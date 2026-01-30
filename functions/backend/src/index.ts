import * as functions from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import type {
  DocumentSnapshot,
  Firestore,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { emitQuizAnalyticsEvent } from "./analytics";
import {
  buildTopicCandidates,
  createTriviaPackFromDocs,
  getRandomQuestionsForTopic,
  resolveTopicId,
} from "./triviaQuestions";

admin.initializeApp();
const db = getFirestore();

/**
 * Firestore Question document shape
 */
interface QuestionDoc {
  id: string;
  topicId: string;
  categoryId: string;
  prompt: string;
  choices: string[];
  correctIndex: number;
  difficulty: string;
  active: boolean;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

interface SharedQuizSnapshotQuestion {
  questionId: string;
  prompt: string;
  choices: string[];
  difficulty: string;
}

interface SerializedTimestamp {
  seconds: number;
  nanoseconds: number;
}

interface TriviaPackRecord {
  id: string;
  topicId: string;
  questionIds: string[];
  createdAt: admin.firestore.Timestamp;
  createdBy?: string;
  status?: string;
  version?: number;
}

interface TriviaPackResponse {
  triviaPackId: string;
  gameId?: string;
  topicId: string;
  questionIds: string[];
  createdAt: admin.firestore.Timestamp;
  createdBy?: string;
  questionsSnapshot: SharedQuizSnapshotQuestion[];
}

interface TriviaPackResponsePayload {
  triviaPackId: string;
  gameId?: string;
  topicId: string;
  questionIds: string[];
  createdAt: SerializedTimestamp;
  createdBy?: string;
  questionsSnapshot: SharedQuizSnapshotQuestion[];
}

interface SharedQuizResponse {
  quizId: string;
  categoryId: string;
  quizSize: number;
  questionDocIds: string[];
  createdBy: string;
  createdAt: admin.firestore.Timestamp;
  expiresAt: admin.firestore.Timestamp;
  questionsSnapshot: SharedQuizSnapshotQuestion[];
}

interface SharedQuizResponsePayload {
  quizId: string;
  categoryId: string;
  quizSize: number;
  questionDocIds: string[];
  createdBy: string;
  createdAt: SerializedTimestamp;
  expiresAt: SerializedTimestamp;
  questionsSnapshot: SharedQuizSnapshotQuestion[];
}

const SHARED_QUIZ_TTL_DAYS = 14;
const sharedQuizCache = new Map<
  string,
  { expiresAtMs: number; payload: SharedQuizResponsePayload }
>();

/**
 * Utility: deterministic shuffle using seeded RNG
 */
function seededShuffle<T>(items: T[], seed: string): T[] {
  let hash = 0;
  for (let i = 0; i < seed.length; i++) {
    hash = (hash << 5) - hash + seed.charCodeAt(i);
    hash |= 0;
  }

  const result = [...items];
  for (let i = result.length - 1; i > 0; i--) {
    hash = (hash * 9301 + 49297) % 233280;
    const j = Math.abs(hash) % (i + 1);
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

/**
 * Utility: ISO week key in UTC (YYYY-Www)
 */
function isoWeekKey(date: Date = new Date()): string {
  const target = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate())
  );
  const dayNr = (target.getUTCDay() + 6) % 7;
  target.setUTCDate(target.getUTCDate() - dayNr + 3);
  const firstThursday = new Date(Date.UTC(target.getUTCFullYear(), 0, 4));
  const firstDayNr = (firstThursday.getUTCDay() + 6) % 7;
  firstThursday.setUTCDate(firstThursday.getUTCDate() - firstDayNr + 3);
  const weekNo =
    1 +
    Math.round(
      (target.getTime() - firstThursday.getTime()) / (7 * 24 * 3600 * 1000)
    );
  return `${target.getUTCFullYear()}-W${String(weekNo).padStart(2, "0")}`;
}

function nowTimestamp(): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date());
}

function cleanUndefined<T extends Record<string, unknown>>(value: T): T {
  return Object.fromEntries(
    Object.entries(value).filter(([, entry]) => entry !== undefined)
  ) as T;
}

function serializeTimestamp(
  timestamp: admin.firestore.Timestamp
): SerializedTimestamp {
  return {
    seconds: timestamp.seconds,
    nanoseconds: timestamp.nanoseconds,
  };
}

function serializeQuestionSnapshot(
  snapshot: SharedQuizSnapshotQuestion
): SharedQuizSnapshotQuestion {
  return {
    questionId: snapshot.questionId,
    prompt: snapshot.prompt,
    choices: Array.isArray(snapshot.choices) ? [...snapshot.choices] : [],
    difficulty: snapshot.difficulty ?? "medium",
  };
}

function normalizeQuestionSnapshot(
  doc: DocumentSnapshot
): SharedQuizSnapshotQuestion {
  const data = doc.data() as QuestionDoc;
  return serializeQuestionSnapshot({
    questionId: doc.id,
    prompt: data.prompt,
    choices: Array.isArray(data.choices) ? data.choices : [],
    difficulty: data.difficulty ?? "medium",
  });
}

async function resolveQuestionsSnapshot(
  questionIds: string[],
  db: Firestore
): Promise<SharedQuizSnapshotQuestion[]> {
  if (questionIds.length === 0) {
    return [];
  }
  const questionRefs = questionIds.map((id) => db.doc(`questions/${id}`));
  const questionDocs = await db.getAll(...questionRefs);
  const questionById = new Map(
    questionDocs
      .filter((doc): doc is QueryDocumentSnapshot => doc.exists)
      .map((doc) => [doc.id, doc])
  );
  return questionIds.map((id) => {
    const doc = questionById.get(id);
    if (!doc) {
      throw new HttpsError(
        "failed-precondition",
        "Trivia pack questions are missing"
      );
    }
    return normalizeQuestionSnapshot(doc);
  });
}

function serializeSharedQuizResponse(
  response: SharedQuizResponse
): SharedQuizResponsePayload {
  return {
    quizId: response.quizId,
    categoryId: response.categoryId,
    quizSize: response.quizSize,
    questionDocIds: [...response.questionDocIds],
    createdBy: response.createdBy,
    createdAt: serializeTimestamp(response.createdAt),
    expiresAt: serializeTimestamp(response.expiresAt),
    questionsSnapshot: response.questionsSnapshot.map(
      serializeQuestionSnapshot
    ),
  };
}

function serializeTriviaPackResponse(
  response: TriviaPackResponse
): TriviaPackResponsePayload {
  return {
    triviaPackId: response.triviaPackId,
    gameId: response.gameId,
    topicId: response.topicId,
    questionIds: [...response.questionIds],
    createdAt: serializeTimestamp(response.createdAt),
    createdBy: response.createdBy,
    questionsSnapshot: response.questionsSnapshot.map(
      serializeQuestionSnapshot
    ),
  };
}

/**
 * Callable: createGame
 */
export const createGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const topicId = request.data?.topicId as string | undefined;
  const triviaPackId = request.data?.triviaPackId as string | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const rawTopicId = typeof topicId === "string" ? topicId.trim() : "";
  const rawPackId = typeof triviaPackId === "string" ? triviaPackId.trim() : "";
  if (!rawTopicId && !rawPackId) {
    throw new HttpsError("invalid-argument", "topicId or triviaPackId is required");
  }

  const requestedSize = 10;
  let triviaPackRefId: string | null = null;
  let questionsSnapshot: SharedQuizSnapshotQuestion[] = [];
  let questionIds: string[] = [];
  let canonicalTopicId = rawTopicId;
  let poolSize = 0;
  let selectionSize = 0;
  let usedExistingPack = false;
  let appliedFilters: Record<string, string[] | string> = {};
  let resolvedFrom = "unknown";
  let mappingIssues: string[] = [];

  if (rawPackId) {
    const packSnap = await db.doc(`triviaPacks/${rawPackId}`).get();
    if (!packSnap.exists) {
      throw new HttpsError("not-found", "Trivia pack not found");
    }
    const packData = packSnap.data() as TriviaPackRecord;
    const packQuestionIds = Array.isArray(packData.questionIds)
      ? packData.questionIds
      : [];
    if (packQuestionIds.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Trivia pack is missing questions"
      );
    }
    usedExistingPack = true;
    triviaPackRefId = packSnap.id;
    canonicalTopicId = packData.topicId ?? rawTopicId;
    questionIds = packQuestionIds;
    questionsSnapshot = await resolveQuestionsSnapshot(packQuestionIds, db);
    poolSize = packQuestionIds.length;
    selectionSize = packQuestionIds.length;

    logger.info("createGame using existing trivia pack", {
      triviaPackId: packSnap.id,
      topicId: canonicalTopicId,
      questionCount: packQuestionIds.length,
    });
  } else {
    const resolved = await resolveTopicId(db, rawTopicId);
    canonicalTopicId = resolved.canonicalTopicId;
    resolvedFrom = resolved.resolvedFrom;
    mappingIssues = resolved.mappingIssues;

    const questionResult = await getRandomQuestionsForTopic(db, {
      topicId: canonicalTopicId,
      limit: requestedSize,
    });
    const selectedDocs = questionResult.docs;
    questionIds = selectedDocs.map((doc) => doc.id);
    selectionSize = selectedDocs.length;
    poolSize = questionResult.eligibleQuestions;
    appliedFilters = {
      topicId: questionResult.appliedFilters.topicIdCandidates,
      categoryId: questionResult.appliedFilters.categoryId ?? [],
    };

    logger.info("createGame question pool", {
      topicId: questionResult.normalizedTopicId,
      inputTopicId: rawTopicId,
      resolvedFrom,
      mappingIssues,
      appliedCandidates: questionResult.appliedFilters.topicIdCandidates,
      appliedFilters,
      poolSize: questionResult.totalQuestions,
      eligibleSize: questionResult.eligibleQuestions,
    });

    if (questionResult.eligibleQuestions < requestedSize) {
      logger.warn("createGame insufficient questions for topic", {
        topicId: questionResult.normalizedTopicId,
        inputTopicId: rawTopicId,
        poolSize: questionResult.eligibleQuestions,
        requestedSize,
        appliedFilters,
      });
    }

    const packResult = await createTriviaPackFromDocs(db, {
      topicId: canonicalTopicId,
      questionDocs: selectedDocs,
      createdBy: uid,
    });
    triviaPackRefId = packResult.packId;

    logger.info("createGame question selection", {
      topicId: canonicalTopicId,
      poolSize,
      selectedCount: selectionSize,
      selectionIds: questionIds.slice(0, 5),
    });

    logger.info("createGame pack summary", {
      topicId: canonicalTopicId,
      finalPackCount: selectionSize,
      triviaPackId: triviaPackRefId,
    });

    const allQuestions: QuestionDoc[] = selectedDocs.map((d) => {
      const data = d.data() as Omit<QuestionDoc, "id">;
      return {
        id: d.id,
        ...data,
      };
    });
    questionsSnapshot = allQuestions.map((q) =>
      serializeQuestionSnapshot({
        questionId: q.id,
        prompt: q.prompt,
        choices: q.choices,
        difficulty: q.difficulty ?? "medium",
      })
    );
  }

  const gameId = db.collection("games").doc().id;
  const gameRef = db.doc(`games/${gameId}`);
  const playerRef = db.doc(`games/${gameId}/players/${uid}`);

  const batch = db.batch();

  batch.set(gameRef, {
    gameId,
    topicId: canonicalTopicId,
    categoryId: canonicalTopicId,
    createdByUid: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "open",
    questionIds,
    questionsSnapshot,
    triviaPackId: triviaPackRefId ?? null,
    packSource: usedExistingPack ? "existing" : "generated",
  });

  batch.set(playerRef, {
    uid,
    startedAt: admin.firestore.FieldValue.serverTimestamp(),
    locked: false,
  });

  await batch.commit();

  emitQuizAnalyticsEvent("quiz_started", {
    categoryId: canonicalTopicId,
    quizSize: selectionSize || questionsSnapshot.length,
    poolSize,
    exhaustedCount: 0,
    weekKey: isoWeekKey(),
    mode: "solo",
    quizId: gameId,
  });

  return {
    gameId,
    topicId: canonicalTopicId,
    categoryId: canonicalTopicId,
    questionsSnapshot,
    triviaPackId: triviaPackRefId ?? null,
    questionIds,
    selectionMeta: {
      exhaustedThisPick: false,
      poolSize,
      weekKey: isoWeekKey(),
    },
  };
});

/**
 * Callable: getWeekKey
 */
export const getWeekKey = onCall(async () => {
  return {
    weekKey: isoWeekKey(),
  };
});

/**
 * Callable: loadGame
 */
export const loadGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const gameId = request.data?.gameId as string | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  if (!gameId) {
    throw new HttpsError("invalid-argument", "gameId is required");
  }

  const gameSnap = await db.doc(`games/${gameId}`).get();
  if (!gameSnap.exists) {
    throw new HttpsError("not-found", "Game not found");
  }

  const data = gameSnap.data() as {
    topicId?: string;
    categoryId?: string;
    questionIds?: string[];
    questionsSnapshot?: SharedQuizSnapshotQuestion[];
  };

  const questionIds = Array.isArray(data.questionIds) ? data.questionIds : [];
  let questionsSnapshot = Array.isArray(data.questionsSnapshot)
    ? data.questionsSnapshot.map(serializeQuestionSnapshot)
    : [];

  if (questionsSnapshot.length === 0 && questionIds.length > 0) {
    const questionRefs = questionIds.map((id) => db.doc(`questions/${id}`));
    const questionDocs = await db.getAll(...questionRefs);
    questionsSnapshot = questionDocs
      .filter((doc): doc is QueryDocumentSnapshot => doc.exists)
      .map(normalizeQuestionSnapshot);
  }

  return {
    gameId,
    topicId: data.topicId ?? data.categoryId,
    categoryId: data.categoryId ?? data.topicId,
    questionsSnapshot,
  };
});

/**
 * Callable: createSharedQuiz
 */
export const createSharedQuiz = onCall(async (request) => {
  const uid = request.auth?.uid;
  const categoryId = request.data?.categoryId as string | undefined;
  const topicId = request.data?.topicId as string | undefined;
  const topic = request.data?.topic as string | undefined;
  const quizSize = request.data?.quizSize as number | undefined;
  const questionIds = request.data?.questionIds as string[] | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  if ((!categoryId && !topicId && !topic) || typeof quizSize !== "number" || quizSize <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "topicId/categoryId/topic and quizSize are required"
    );
  }

  const resolved = await resolveTopicId(db, topicId, categoryId, topic);
  let selectedIds: string[] = [];
  let selectedDocs: QueryDocumentSnapshot[] = [];
  let poolSize = 0;

  if (Array.isArray(questionIds) && questionIds.length > 0) {
    const uniqueIds = Array.from(new Set(questionIds));
    const questionRefs = uniqueIds.map((id) =>
      db.doc(`questions/${id}`)
    );
    const docs = await db.getAll(...questionRefs);
    const existingDocs = docs.filter(
      (doc): doc is QueryDocumentSnapshot => doc.exists
    );
    if (existingDocs.length !== uniqueIds.length) {
      throw new HttpsError(
        "failed-precondition",
        "Shared quiz contains missing questions",
        { missingCount: uniqueIds.length - existingDocs.length }
      );
    }
    poolSize = existingDocs.length;
    const mismatched = existingDocs.filter((doc) => {
      const data = doc.data() as QuestionDoc;
      const docTopicId = data.topicId ?? data.categoryId;
      return (
        docTopicId !== resolved.canonicalTopicId &&
        docTopicId !== resolved.inputCategoryId
      );
    });
    if (mismatched.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        "Shared quiz questions do not match category",
        { mismatchedCount: mismatched.length }
      );
    }
    selectedDocs = existingDocs.slice(0, quizSize);
    selectedIds = selectedDocs.map((doc) => doc.id);
    if (selectedIds.length < quizSize) {
      throw new HttpsError(
        "failed-precondition",
        "Not enough questions to create shared quiz"
      );
    }
  } else {
    const questionResult = await getRandomQuestionsForTopic(db, {
      topicId: resolved.canonicalTopicId,
      categoryId: resolved.inputCategoryId,
      limit: quizSize,
    });
    const questionDocs = questionResult.docs;
    if (questionDocs.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "NO_QUESTIONS_EXIST_FOR_TOPIC",
        {
          code: "NO_QUESTIONS_EXIST_FOR_TOPIC",
          topic: resolved.canonicalTopicId,
          inputTopicId: resolved.inputTopicId,
          inputCategoryId: resolved.inputCategoryId,
          inputTopic: resolved.inputTopic,
          resolvedFrom: resolved.resolvedFrom,
          mappingIssues: resolved.mappingIssues,
          totalQuestions: questionResult.totalQuestions,
          collection: "questions",
          candidateValues: buildTopicCandidates(resolved),
          appliedFilter: "topicId",
        }
      );
    }

    const poolIds = questionDocs.map((doc) => doc.id);
    poolSize = questionResult.eligibleQuestions;
    if (questionResult.eligibleQuestions < quizSize) {
      throw new HttpsError(
        "failed-precondition",
        `Not enough questions for topic ${questionResult.normalizedTopicId}. Found ${questionResult.eligibleQuestions}, need ${quizSize}.`,
        {
          code: "INSUFFICIENT_QUESTIONS",
          topicId: questionResult.normalizedTopicId,
          requestedSize: quizSize,
          poolSize: questionResult.eligibleQuestions,
        }
      );
    }

    const seed = `shared-${resolved.canonicalTopicId}-${quizSize}`;
    selectedIds = seededShuffle(poolIds, seed).slice(0, quizSize);
    const questionById = new Map(
      questionDocs.map((doc) => [doc.id, doc])
    );
    selectedDocs = selectedIds.map((id) => {
      const doc = questionById.get(id);
      if (!doc) {
        throw new HttpsError(
          "failed-precondition",
          "Selected question set could not be resolved"
        );
      }
      return doc;
    });
  }

  const questionsSnapshot = selectedDocs.map(normalizeQuestionSnapshot);
  const quizId = db.collection("sharedQuizzes").doc().id;
  const createdAt = nowTimestamp();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + SHARED_QUIZ_TTL_DAYS * 24 * 60 * 60 * 1000)
  );

  const sharedQuizDoc = {
    quizId,
    categoryId: resolved.inputCategoryId ?? resolved.canonicalTopicId,
    quizSize,
    questionDocIds: selectedIds,
    createdBy: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
    questionsSnapshot,
  };

  await db.doc(`sharedQuizzes/${quizId}`).set(sharedQuizDoc);

  emitQuizAnalyticsEvent("quiz_shared_created", {
    categoryId: resolved.canonicalTopicId,
    quizSize,
    poolSize,
    exhaustedCount: 0,
    weekKey: isoWeekKey(),
    mode: "shared",
    quizId,
  });

  const response: SharedQuizResponse = {
    quizId,
    categoryId: resolved.inputCategoryId ?? resolved.canonicalTopicId,
    quizSize,
    questionDocIds: selectedIds,
    createdBy: uid,
    createdAt,
    expiresAt,
    questionsSnapshot,
  };

  const payload = serializeSharedQuizResponse(response);
  sharedQuizCache.set(quizId, {
    expiresAtMs: expiresAt.toMillis(),
    payload,
  });

  return payload;
});

/**
 * Callable: getSharedQuiz
 */
export const getSharedQuiz = onCall(async (request) => {
  const quizId = request.data?.quizId as string | undefined;

  if (!quizId) {
    throw new HttpsError("invalid-argument", "quizId is required");
  }

  const cached = sharedQuizCache.get(quizId);
  if (cached && cached.expiresAtMs > Date.now()) {
    return cached.payload;
  }

  const sharedQuizSnap = await db.doc(`sharedQuizzes/${quizId}`).get();
  if (!sharedQuizSnap.exists) {
    throw new HttpsError("not-found", "Shared quiz not found");
  }

  const data = sharedQuizSnap.data() as SharedQuizResponse;
  const expiresAt = data.expiresAt;
  if (expiresAt.toMillis() <= Date.now()) {
    throw new HttpsError("failed-precondition", "Shared quiz expired");
  }

  const questionDocIds =
    (data as SharedQuizResponse).questionDocIds ??
    (data as unknown as { questionIds?: string[] }).questionIds;
  if (!Array.isArray(questionDocIds) || questionDocIds.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Shared quiz is missing questions"
    );
  }

  let questionsSnapshot = Array.isArray(data.questionsSnapshot)
    ? data.questionsSnapshot.map(serializeQuestionSnapshot)
    : [];
  if (questionsSnapshot.length === 0) {
    const questionRefs = questionDocIds.map((id) =>
      db.doc(`questions/${id}`)
    );
    const questionDocs = await db.getAll(...questionRefs);
    questionsSnapshot = questionDocs.map(normalizeQuestionSnapshot);
  }

  const response: SharedQuizResponse = {
    quizId,
    categoryId: data.categoryId,
    quizSize: data.quizSize,
    questionDocIds,
    createdBy: data.createdBy,
    createdAt: data.createdAt,
    expiresAt: data.expiresAt,
    questionsSnapshot,
  };

  const payload = serializeSharedQuizResponse(response);
  sharedQuizCache.set(quizId, {
    expiresAtMs: expiresAt.toMillis(),
    payload,
  });

  return payload;
});

/**
 * Callable: getTriviaPack
 */
export const getTriviaPack = onCall(async (request) => {
  const triviaPackId = request.data?.triviaPackId as string | undefined;

  if (!triviaPackId) {
    throw new HttpsError("invalid-argument", "triviaPackId is required");
  }

  const packSnap = await db.doc(`triviaPacks/${triviaPackId}`).get();
  if (!packSnap.exists) {
    throw new HttpsError("not-found", "Trivia pack not found");
  }

  const data = packSnap.data() as TriviaPackRecord;
  const questionIds = Array.isArray(data.questionIds) ? data.questionIds : [];
  if (questionIds.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Trivia pack is missing questions"
    );
  }

  const questionsSnapshot = await resolveQuestionsSnapshot(
    questionIds,
    db
  );

  const response: TriviaPackResponse = {
    triviaPackId: packSnap.id,
    topicId: data.topicId,
    questionIds,
    createdAt: data.createdAt,
    createdBy: data.createdBy,
    questionsSnapshot,
  };

  return serializeTriviaPackResponse({
    ...response,
    gameId: packSnap.id,
  });
});

/**
 * Callable: submitSoloScore
 */
export const submitSoloScore = onCall(async (request) => {
  try {
    const data = (request.data ?? {}) as {
      gameId?: string;
      categoryId?: string;
      score?: number;
      correctCount?: number;
      totalQuestions?: number;
      mode?: "solo";
      durationMs?: number;
      triviaPackId?: string;
    };
    console.log("submitSoloScore payload", data);
    logger.info("submitSoloScore request payload", {
      data,
    });

    const uid = request.auth?.uid;
    const gameId = data.gameId;
    const triviaPackId = data.triviaPackId ?? gameId;
    const categoryId = data.categoryId;
    const scoreInput = data.score;
    const correctCountInput = data.correctCount;
    const totalQuestionsInput = data.totalQuestions;
    const mode = data.mode;
    const durationMsInput = data.durationMs;
    const isValidNumber = (value: unknown): value is number =>
      typeof value === "number" && Number.isFinite(value);

    if (
      !uid ||
      typeof gameId !== "string" ||
      gameId.trim().length === 0 ||
      typeof categoryId !== "string" ||
      categoryId.trim().length === 0 ||
      mode !== "solo" ||
      !isValidNumber(scoreInput) ||
      !isValidNumber(correctCountInput) ||
      !isValidNumber(totalQuestionsInput)
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required score fields"
      );
    }
    if (!triviaPackId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required score fields"
      );
    }

    const scoreRef = db.collection("soloScores").doc(gameId);
    const packScoreRef = db.doc(`triviaPacks/${triviaPackId}/scores/${uid}`);
    const userRef = db.doc(`users/${uid}`);

    await db.runTransaction(async (transaction) => {
      const packSnap = await transaction.get(
        db.doc(`triviaPacks/${triviaPackId}`)
      );
      if (!packSnap.exists) {
        throw new HttpsError("not-found", "Trivia pack not found");
      }

      const packData = packSnap.data() as TriviaPackRecord;
      const questionIds = Array.isArray(packData.questionIds)
        ? packData.questionIds
        : [];
      if (questionIds.length === 0) {
        throw new HttpsError(
          "failed-precondition",
          "Trivia pack is missing questions"
        );
      }

      const existing = await transaction.get(scoreRef);
      const weekKey = isoWeekKey();
      const safeNumber = (value: unknown, fallback = 0): number => {
        if (typeof value !== "number") {
          return fallback;
        }
        return Number.isFinite(value) ? value : fallback;
      };
      const maxScore = Math.max(0, Math.floor(questionIds.length));

      if (existing.exists) {
        logger.info("submitSoloScore duplicate score submission", {
          gameId,
          triviaPackId,
          uid,
        });
        return;
      }

      const safeScore = Math.max(0, Math.floor(safeNumber(scoreInput, 0)));
      const safeTotal = Math.max(
        0,
        Math.floor(safeNumber(totalQuestionsInput, maxScore))
      );
      const safeCorrect = Math.min(
        safeTotal,
        Math.max(0, Math.floor(safeNumber(correctCountInput, safeScore)))
      );
      const durationSeconds =
        typeof durationMsInput === "number" && Number.isFinite(durationMsInput)
          ? Math.max(0, Math.floor(durationMsInput / 1000))
          : undefined;
      const xpEarned = Math.max(0, safeCorrect * 100);

      const completedAt = admin.firestore.FieldValue.serverTimestamp();
      const scoreEntry = cleanUndefined({
        uid,
        score: safeScore,
        maxScore,
        correct: safeCorrect,
        durationSeconds,
        completedAt,
      });

      const gamePayload = cleanUndefined({
        ...scoreEntry,
        gameId,
        triviaPackId,
        total: safeTotal,
        xpEarned,
      });

      transaction.set(scoreRef, gamePayload, { merge: false });
      transaction.set(
        packScoreRef,
        cleanUndefined({
          ...scoreEntry,
          gameId,
        }),
        { merge: true }
      );

      const cursorIncrement = Math.max(0, safeTotal);
      const exhaustedIncrement = 0;
      transaction.set(
        db.doc(`users/${uid}/categoryProgress/${categoryId}`),
        {
          weekKey,
          cursor: admin.firestore.FieldValue.increment(cursorIncrement),
          exhaustedCount: admin.firestore.FieldValue.increment(exhaustedIncrement),
        },
        { merge: true }
      );

      const userSnap = await transaction.get(userRef);
      const userData = userSnap.data() as
        | { stats?: { bestStreak?: number } }
        | undefined;
      const existingBestStreak = Math.max(
        0,
        Math.floor(safeNumber(userData?.stats?.bestStreak, 0))
      );
      const nextBestStreak = Math.max(existingBestStreak, safeCorrect);
      transaction.set(
        userRef,
        {
          stats: {
            gamesPlayed: admin.firestore.FieldValue.increment(1),
            questionsAnswered:
              admin.firestore.FieldValue.increment(safeTotal),
            correctAnswers:
              admin.firestore.FieldValue.increment(safeCorrect),
            xp: admin.firestore.FieldValue.increment(xpEarned),
            bestStreak: nextBestStreak,
          },
        },
        { merge: true }
      );

      return;
    });

    return { ok: true };
  } catch (error) {
    logger.error("submitSoloScore failed", {
      error,
      triviaPackId: request.data?.triviaPackId,
      gameId: request.data?.gameId,
      uid: request.auth?.uid,
    });
    if (
      error instanceof functions.https.HttpsError &&
      error.code === "invalid-argument"
    ) {
      throw error;
    }
    const message = error instanceof Error ? error.message : "Unknown error";
    throw new functions.https.HttpsError("internal", message);
  }
});

/**
 * Callable: completeGame
 */
export const completeGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const gameId = request.data?.gameId as string | undefined;
  const answers = Array.isArray(request.data?.answers)
    ? (request.data?.answers as {
        questionId: string;
        selectedIndex: number;
      }[])
    : [];

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  if (!gameId) {
    throw new HttpsError("not-found", "Game not found");
  }

  const gameRef = db.doc(`games/${gameId}`);
  const playerRef = db.doc(`games/${gameId}/players/${uid}`);

  const [gameSnap, playerSnap] = await Promise.all([
    gameRef.get(),
    playerRef.get(),
  ]);

  if (!gameSnap.exists) {
    throw new HttpsError("not-found", "Game not found");
  }

  const gameData = gameSnap.data() as {
    createdByUid?: string;
    completedAt?: admin.firestore.Timestamp | null;
    questionIds?: string[];
    topicId?: string;
  };
  if (gameData.createdByUid && gameData.createdByUid !== uid) {
    throw new HttpsError("permission-denied", "UID mismatch");
  }
  if (gameData.completedAt != null || playerSnap.data()?.locked) {
    return { ok: true, alreadyCompleted: true };
  }

  const questionIds: string[] = Array.isArray(gameData.questionIds)
    ? gameData.questionIds
    : [];
  const topicId: string = gameData.topicId as string;

  const questionDocs = await Promise.all(
    questionIds.map((qid) => db.doc(`questions/${qid}`).get())
  );

  const correctIndexById: Record<string, number> = {};
  questionDocs.forEach((doc) => {
    if (doc.exists) {
      correctIndexById[doc.id] = doc.data()!.correctIndex;
    }
  });

  let score = 0;

  const scoredAnswers = answers.map((a) => {
    const isCorrect =
      correctIndexById[a.questionId] === a.selectedIndex;
    if (isCorrect) score++;
    return {
      questionId: a.questionId,
      selectedIndex: a.selectedIndex,
      isCorrect,
    };
  });

  const batch = db.batch();

  batch.set(
    playerRef,
    {
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      score,
      maxScore: questionIds.length,
      answers: scoredAnswers,
      locked: true,
    },
    { merge: true }
  );
  batch.set(
    gameRef,
    {
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await batch.commit();

  void (async () => {
    emitQuizAnalyticsEvent("quiz_completed", {
      categoryId: topicId,
      quizSize: questionIds.length,
      exhaustedCount: 0,
      weekKey: isoWeekKey(),
      mode: "solo",
      quizId: gameId,
    });
  })();

  return { score, maxScore: questionIds.length };
});

export * from "./quizSelection";
export * from "./admin/diagnostics";
