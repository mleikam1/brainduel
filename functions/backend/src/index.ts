import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";
import type { FirebaseFirestore } from "firebase-admin";
import { emitQuizAnalyticsEvent } from "./analytics";
import {
  createTriviaPackFromDocs,
  resolveTopicId,
  selectRandomDocs,
} from "./triviaQuestions";

admin.initializeApp();
const db = admin.firestore();

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

interface TriviaPackRecord {
  id: string;
  topicId: string;
  questionIds: string[];
  createdAt: admin.firestore.Timestamp;
  createdBy?: string;
}

interface TriviaPackResponse {
  triviaPackId: string;
  topicId: string;
  questionIds: string[];
  createdAt: admin.firestore.Timestamp;
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

const SHARED_QUIZ_TTL_DAYS = 14;
const sharedQuizCache = new Map<
  string,
  { expiresAtMs: number; payload: SharedQuizResponse }
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

function normalizeQuestionSnapshot(
  doc: FirebaseFirestore.DocumentSnapshot
): SharedQuizSnapshotQuestion {
  const data = doc.data() as QuestionDoc;
  return {
    questionId: doc.id,
    prompt: data.prompt,
    choices: data.choices,
    difficulty: data.difficulty ?? "medium",
  };
}

async function resolveQuestionsSnapshot(
  questionIds: string[],
  db: FirebaseFirestore.Firestore
): Promise<SharedQuizSnapshotQuestion[]> {
  if (questionIds.length === 0) {
    return [];
  }
  const questionRefs = questionIds.map((id) => db.doc(`questions/${id}`));
  const questionDocs = await db.getAll(...questionRefs);
  const questionById = new Map(
    questionDocs.filter((doc) => doc.exists).map((doc) => [doc.id, doc])
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

/**
 * Callable: createGame
 */
export const createGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const topicId = request.data?.topicId as string | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const rawTopicId = typeof topicId === "string" ? topicId.trim() : "";
  if (!rawTopicId) {
    throw new HttpsError("invalid-argument", "topicId is required");
  }
  const resolved = await resolveTopicId(db, rawTopicId);
  const canonicalTopicId = resolved.canonicalTopicId;

  const requestedSize = 10;
  let questionDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];
  let triviaPackRefId: string | null = null;
  let usedFallback = false;

  const topicQuerySnap = await db
    .collection("questions")
    .where("topicId", "==", canonicalTopicId)
    .get();
  logger.info("createGame topic query", {
    topicId: canonicalTopicId,
    inputTopicId: rawTopicId,
    resolvedFrom: resolved.resolvedFrom,
    mappingIssues: resolved.mappingIssues,
    topicQueryCount: topicQuerySnap.size,
  });

  if (topicQuerySnap.empty) {
    usedFallback = true;
    logger.warn("createGame topic query empty; falling back to all questions", {
      topicId: canonicalTopicId,
      inputTopicId: rawTopicId,
      query: { topicId: canonicalTopicId },
    });
    const fallbackSnap = await db.collection("questions").get();
    questionDocs = fallbackSnap.docs;
  } else {
    questionDocs = topicQuerySnap.docs;
  }

  if (questionDocs.length === 0) {
    logger.warn("createGame no questions available after fallback", {
      topicId: canonicalTopicId,
      inputTopicId: rawTopicId,
      usedFallback,
    });
    throw new HttpsError("failed-precondition", "No questions available");
  }

  const selectedDocs = selectRandomDocs(questionDocs, requestedSize);
  const allQuestions: QuestionDoc[] = selectedDocs.map((d) => {
    const data = d.data() as Omit<QuestionDoc, "id">;
    return {
      id: d.id,
      ...data,
    };
  });

  const packResult = await createTriviaPackFromDocs(db, {
    topicId: canonicalTopicId,
    questionDocs: selectedDocs,
    createdBy: uid,
  });
  triviaPackRefId = packResult.packId;

  const gameId = db.collection("games").doc().id;
  const poolSize = allQuestions.length;
  const selected: QuestionDoc[] = allQuestions;
  const selectionSize = selected.length;

  logger.info("createGame question selection", {
    topicId: canonicalTopicId,
    poolSize,
    selectedCount: selected.length,
    usedFallback,
    selectionIds: selected.slice(0, 5).map((q) => q.id),
  });

  logger.info("createGame pack summary", {
    topicId: canonicalTopicId,
    usedFallback,
    finalPackCount: selectionSize,
  });

  const questionsSnapshot = selected.map((q) => ({
    questionId: q.id,
    prompt: q.prompt,
    choices: q.choices,
    difficulty: q.difficulty ?? "medium",
  }));

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
    questionIds: selected.map((q) => q.id),
    questionsSnapshot,
    triviaPackId: triviaPackRefId ?? null,
  });

  batch.set(playerRef, {
    uid,
    startedAt: admin.firestore.FieldValue.serverTimestamp(),
    locked: false,
  });

  await batch.commit();

  emitQuizAnalyticsEvent("quiz_started", {
    categoryId: canonicalTopicId,
    quizSize: selectionSize,
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
    ? data.questionsSnapshot
    : [];

  if (questionsSnapshot.length === 0 && questionIds.length > 0) {
    const questionRefs = questionIds.map((id) => db.doc(`questions/${id}`));
    const questionDocs = await db.getAll(...questionRefs);
    questionsSnapshot = questionDocs
      .filter((doc) => doc.exists)
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
  let selectedDocs: FirebaseFirestore.DocumentSnapshot[] = [];
  let poolSize = 0;

  if (Array.isArray(questionIds) && questionIds.length > 0) {
    const uniqueIds = Array.from(new Set(questionIds));
    const questionRefs = uniqueIds.map((id) =>
      db.doc(`questions/${id}`)
    );
    const docs = await db.getAll(...questionRefs);
    const existingDocs = docs.filter((doc) => doc.exists);
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
          totalQuestions: 0,
          collection: "questions",
          candidateValues: buildTopicCandidates(resolved),
          appliedFilter: "topicId",
        }
      );
    }

    const poolIds = questionDocs.map((doc) => doc.id);
    poolSize = questionResult.totalQuestions;
    if (questionResult.totalQuestions < quizSize) {
      throw new HttpsError(
        "failed-precondition",
        "Not enough questions to create shared quiz"
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

  sharedQuizCache.set(quizId, {
    expiresAtMs: expiresAt.toMillis(),
    payload: response,
  });

  return response;
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

  let questionsSnapshot = data.questionsSnapshot;
  if (!Array.isArray(questionsSnapshot) || questionsSnapshot.length === 0) {
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

  sharedQuizCache.set(quizId, {
    expiresAtMs: expiresAt.toMillis(),
    payload: response,
  });

  return response;
});

/**
 * Callable: getTriviaPack
 */
export const getTriviaPack = onCall(async (request) => {
  const triviaPackId = request.data?.triviaPackId as string | undefined;

  if (!triviaPackId) {
    throw new HttpsError("invalid-argument", "triviaPackId is required");
  }

  const packSnap = await db.doc(`trivia_packs/${triviaPackId}`).get();
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

  return response;
});

/**
 * Callable: completeGame
 */
export const completeGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const gameId = request.data?.gameId as string | undefined;
  const answers = request.data?.answers as
    | { questionId: string; selectedIndex: number }[]
    | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  if (!gameId || !Array.isArray(answers)) {
    throw new HttpsError(
      "invalid-argument",
      "gameId and answers are required"
    );
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
  if (!playerSnap.exists) {
    throw new HttpsError("failed-precondition", "Player not registered");
  }
  if (playerSnap.data()!.locked) {
    throw new HttpsError(
      "failed-precondition",
      "Game already completed"
    );
  }

  const gameData = gameSnap.data()!;
  const questionIds: string[] = gameData.questionIds;
  const topicId: string = gameData.topicId;

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

  batch.update(playerRef, {
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    score,
    maxScore: questionIds.length,
    answers: scoredAnswers,
    locked: true,
  });

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
