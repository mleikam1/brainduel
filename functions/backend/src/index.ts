import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { emitQuizAnalyticsEvent } from "./analytics";

admin.initializeApp();
const db = admin.firestore();

/**
 * Firestore Question document shape
 */
interface QuestionDoc {
  id: string;
  prompt: string;
  choices: string[];
  correctIndex: number;
  difficulty?: string;
  topicId: string;
  active: boolean;
}

interface CategoryProgress {
  seed: string;
  cursor: number;
  exhaustedCount: number;
  weekKey: string;
}

interface SharedQuizSnapshotQuestion {
  questionId: string;
  prompt: string;
  choices: string[];
  difficulty: string;
}

interface TriviaPackDoc {
  topicId?: string;
  categoryId?: string;
  questionIds?: string[];
  quizSize?: number;
  size?: number;
  enabled?: boolean;
  isEnabled?: boolean;
}

interface TopicResolution {
  canonicalTopicId: string;
  inputTopicId?: string;
  inputCategoryId?: string;
  inputTopic?: string;
  resolvedFrom: string;
  mappingIssues: string[];
  categoryFallbackId?: string;
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

async function resolveTopicId(
  topicId?: string,
  categoryId?: string,
  topic?: string
): Promise<TopicResolution> {
  const trimmedTopicId = typeof topicId === "string" ? topicId.trim() : "";
  const trimmedCategoryId =
    typeof categoryId === "string" ? categoryId.trim() : "";
  const trimmedTopic = typeof topic === "string" ? topic.trim() : "";
  const inputTopicId = trimmedTopicId || undefined;
  const inputCategoryId = trimmedCategoryId || undefined;
  const inputTopic = trimmedTopic || undefined;

  const canonicalInput = inputTopicId ?? inputCategoryId ?? inputTopic;

  if (!canonicalInput) {
    throw new HttpsError("invalid-argument", "Missing topic");
  }

  const mappingIssues: string[] = [];
  let resolvedFrom = "fallback";
  let canonicalTopicId = canonicalInput;
  let categoryFallbackId =
    inputCategoryId && inputCategoryId !== canonicalTopicId
      ? inputCategoryId
      : undefined;

  const topicDocRef = db.doc(`topics/${canonicalTopicId}`);
  const categoryDocRef = db.doc(`categories/${canonicalTopicId}`);
  const [topicSnap, categorySnap] = await Promise.all([
    topicDocRef.get(),
    categoryDocRef.get(),
  ]);

  if (topicSnap.exists) {
    resolvedFrom = "topics";
  } else if (categorySnap.exists) {
    resolvedFrom = "categories";
    const data = categorySnap.data() as { topicId?: string; id?: string };
    if (typeof data?.topicId === "string" && data.topicId.trim()) {
      canonicalTopicId = data.topicId.trim();
      categoryFallbackId = categoryFallbackId ?? inputCategoryId;
    } else if (typeof data?.id === "string" && data.id.trim()) {
      canonicalTopicId = data.id.trim();
    }
  } else if (inputCategoryId && inputTopicId && inputCategoryId !== inputTopicId) {
    categoryFallbackId = inputCategoryId;
    mappingIssues.push("topicId and categoryId differ");
  }

  if (!topicSnap.exists && !categorySnap.exists) {
    mappingIssues.push("no matching topic/category doc");
  }

  return {
    canonicalTopicId,
    inputTopicId,
    inputCategoryId,
    inputTopic,
    resolvedFrom,
    mappingIssues,
    categoryFallbackId,
  };
}

async function fetchQuestionsForTopic(
  topicId: string,
  categoryFallbackId?: string
): Promise<{
  snapshot: FirebaseFirestore.QuerySnapshot | null;
  appliedFilter: string;
  filterCounts: Record<string, number>;
}> {
  const selectionSize = 10;
  const queryLimit = selectionSize * 6;
  const categoryQueryId = categoryFallbackId ?? topicId;

  const filterCounts: Record<string, number> = {};
  const topicQuery = db
    .collection("questions")
    .where("topicId", "==", topicId)
    .limit(queryLimit);
  const categoryQuery = db
    .collection("questions")
    .where("categoryId", "==", categoryQueryId)
    .limit(queryLimit);

  const topicSnap = await topicQuery.get();
  filterCounts.topicId = topicSnap.size;
  logger.info("createGame question query", {
    topicId,
    filter: "topicId",
    count: topicSnap.size,
  });

  if (!topicSnap.empty) {
    return {
      snapshot: topicSnap,
      appliedFilter: "topicId",
      filterCounts,
    };
  }

  const categorySnap = await categoryQuery.get();
  filterCounts.categoryId = categorySnap.size;
  logger.info("createGame question query", {
    topicId,
    filter: "categoryId",
    count: categorySnap.size,
  });

  return {
    snapshot: categorySnap.empty ? null : categorySnap,
    appliedFilter: "categoryId",
    filterCounts,
  };
}

/**
 * Callable: createGame
 */
export const createGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const topicId = request.data?.topicId as string | undefined;
  const categoryId = request.data?.categoryId as string | undefined;
  const topic = request.data?.topic as string | undefined;
  const triviaPackId = request.data?.triviaPackId as string | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const resolved = await resolveTopicId(topicId, categoryId, topic);
  const canonicalTopicId = resolved.canonicalTopicId;
  const progressRef = db.doc(
    `users/${uid}/categoryProgress/${canonicalTopicId}`
  );

  let questionDocs: FirebaseFirestore.DocumentSnapshot[] = [];
  let appliedFilter = "none";
  let filterCounts: Record<string, number> = {};
  let packTopicId: string | undefined;
  let packQuestionIds: string[] | undefined;
  let packIssues: string[] = [];

  if (typeof triviaPackId === "string" && triviaPackId.trim()) {
    const packSnap = await db.doc(`trivia_packs/${triviaPackId}`).get();
    if (packSnap.exists) {
      const packData = packSnap.data() as TriviaPackDoc;
      const packEnabled =
        (typeof packData.isEnabled === "boolean"
          ? packData.isEnabled
          : packData.enabled) ?? true;
      if (!packEnabled) {
        throw new HttpsError(
          "failed-precondition",
          "Trivia pack is disabled",
          { triviaPackId }
        );
      }
      packTopicId =
        packData.topicId ??
        packData.categoryId ??
        canonicalTopicId;
      if (Array.isArray(packData.questionIds)) {
        packQuestionIds = packData.questionIds.filter(
          (id) => typeof id === "string" && id.trim().length > 0
        );
      }
      if (!packQuestionIds || packQuestionIds.length === 0) {
        packIssues.push("pack has no questionIds");
      }
    } else {
      packIssues.push("pack not found");
    }
  }

  if (packQuestionIds && packQuestionIds.length > 0) {
    const questionRefs = packQuestionIds.map((id) =>
      db.doc(`questions/${id}`)
    );
    const docs = await db.getAll(...questionRefs);
    questionDocs = docs.filter((doc) => doc.exists);
    appliedFilter = "trivia_pack";
    filterCounts.trivia_pack = questionDocs.length;
    if (questionDocs.length !== packQuestionIds.length) {
      packIssues.push("pack contains missing questions");
    }
  } else {
    const queryResult = await fetchQuestionsForTopic(
      packTopicId ?? canonicalTopicId,
      resolved.categoryFallbackId
    );
    questionDocs = queryResult.snapshot?.docs ?? [];
    appliedFilter = queryResult.appliedFilter;
    filterCounts = queryResult.filterCounts;
  }

  if (questionDocs.length === 0) {
    logger.warn("createGame no questions found", {
      topicId: canonicalTopicId,
      inputTopicId: resolved.inputTopicId,
      inputCategoryId: resolved.inputCategoryId,
      inputTopic: resolved.inputTopic,
    });
    throw new HttpsError(
      "failed-precondition",
      "NO_QUESTIONS_AVAILABLE",
      {
        topic: canonicalTopicId,
        totalQuestions: 0,
        collection: "questions",
        testedFields: ["topicId", "categoryId"],
      }
    );
  }

  const allQuestions: QuestionDoc[] = questionDocs.map((d) => {
    const data = d.data() as Omit<QuestionDoc, "id">;
    return {
      id: d.id,
      ...data,
    };
  });

  const gameId = db.collection("games").doc().id;
  const progressSnap = await progressRef.get();

  const weekKey = isoWeekKey();
  const progressData = progressSnap.data() as
    | Partial<CategoryProgress>
    | undefined;
  const progressWeekKey = progressData?.weekKey;
  const isSameWeek = progressWeekKey === weekKey;
  const seed =
    isSameWeek && typeof progressData?.seed === "string"
      ? progressData.seed
      : `${uid}-${canonicalTopicId}-${weekKey}`;
  const existingCursor = Number.isInteger(progressData?.cursor)
    ? (progressData!.cursor as number)
    : 0;
  const cursorStart = isSameWeek ? existingCursor : 0;
  const existingExhausted = Number.isInteger(progressData?.exhaustedCount)
    ? (progressData!.exhaustedCount as number)
    : 0;
  const exhaustedBase = isSameWeek ? existingExhausted : 0;

  const poolSize = allQuestions.length;
  if (poolSize < 10) {
    logger.warn("createGame insufficient question pool", {
      topicId: canonicalTopicId,
      poolSize,
      appliedFilter,
    });
    throw new HttpsError(
      "failed-precondition",
      "Not enough questions to create game",
      {
        code: "NO_QUESTIONS_AVAILABLE",
        topicId: canonicalTopicId,
        inputTopicId: resolved.inputTopicId,
        inputCategoryId: resolved.inputCategoryId,
        resolvedFrom: resolved.resolvedFrom,
        mappingIssues: resolved.mappingIssues,
        poolSize,
        appliedFilter,
        questionCount: questionDocs.length,
        fieldsTested: ["topicId", "categoryId"],
        triviaPackId,
        packIssues,
      }
    );
  }

  const shuffled = seededShuffle(allQuestions, seed);
  const cursorBefore = ((cursorStart % poolSize) + poolSize) % poolSize;
  const selectionSize = 10;
  const end = cursorBefore + selectionSize;
  let selected: QuestionDoc[] = [];
  let cursorAfter = 0;
  let exhaustedThisPick = false;
  if (end <= poolSize) {
    selected = shuffled.slice(cursorBefore, end);
    cursorAfter = end === poolSize ? 0 : end;
    exhaustedThisPick = end === poolSize;
  } else {
    selected = [
      ...shuffled.slice(cursorBefore),
      ...shuffled.slice(0, end - poolSize),
    ];
    cursorAfter = end - poolSize;
    exhaustedThisPick = true;
  }

  if (selected.length < 10) {
    logger.warn("createGame selection too small", {
      topicId: canonicalTopicId,
      selectedCount: selected.length,
      poolSize,
      appliedFilter,
    });
    throw new HttpsError(
      "failed-precondition",
      "Not enough questions to create game",
      {
        code: "NO_QUESTIONS_AVAILABLE",
        topicId: canonicalTopicId,
        inputTopicId: resolved.inputTopicId,
        inputCategoryId: resolved.inputCategoryId,
        resolvedFrom: resolved.resolvedFrom,
        mappingIssues: resolved.mappingIssues,
        poolSize,
        appliedFilter,
        questionCount: questionDocs.length,
        fieldsTested: ["topicId", "categoryId"],
        triviaPackId,
        packIssues,
      }
    );
  }

  logger.info("createGame question selection", {
    topicId: canonicalTopicId,
    appliedFilter,
    poolSize,
    selectedCount: selected.length,
    selectionIds: selected.slice(0, 5).map((q) => q.id),
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
    categoryId: resolved.inputCategoryId ?? canonicalTopicId,
    createdByUid: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "open",
    questionIds: selected.map((q) => q.id),
    questionsSnapshot,
    triviaPackId: triviaPackId ?? null,
  });

  batch.set(playerRef, {
    uid,
    startedAt: admin.firestore.FieldValue.serverTimestamp(),
    locked: false,
  });

  batch.set(
    progressRef,
    {
      seed,
      cursor: cursorAfter,
      exhaustedCount: exhaustedBase + (exhaustedThisPick ? 1 : 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      weekKey,
    },
    { merge: true }
  );

  await batch.commit();

  const exhaustedCount =
    exhaustedBase + (exhaustedThisPick ? 1 : 0);

  emitQuizAnalyticsEvent("quiz_started", {
    categoryId: canonicalTopicId,
    quizSize: selectionSize,
    poolSize,
    exhaustedCount,
    weekKey,
    mode: "solo",
    quizId: gameId,
  });

  if (exhaustedThisPick) {
    emitQuizAnalyticsEvent("category_exhausted", {
      categoryId: canonicalTopicId,
      quizSize: selectionSize,
      poolSize,
      exhaustedCount,
      weekKey,
      mode: "solo",
      quizId: gameId,
    });
  }

  return {
    gameId,
    topicId: canonicalTopicId,
    categoryId: resolved.inputCategoryId ?? canonicalTopicId,
    questionsSnapshot,
    selectionMeta: {
      exhaustedThisPick,
      poolSize,
      cursorBefore,
      cursorAfter,
      weekKey,
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

  const resolved = await resolveTopicId(topicId, categoryId, topic);
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
      return (
        data.topicId !== resolved.canonicalTopicId &&
        data.topicId !== resolved.inputCategoryId
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
    let questionsSnap = await db
      .collection("questions")
      .where("topicId", "==", resolved.canonicalTopicId)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500)
      .get();

    if (questionsSnap.empty) {
      const fallbackTopicId = resolved.categoryFallbackId ?? resolved.inputCategoryId;
      if (fallbackTopicId) {
        questionsSnap = await db
          .collection("questions")
          .where("categoryId", "==", fallbackTopicId)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(500)
          .get();
      }
    }

    if (questionsSnap.empty) {
      throw new HttpsError(
        "failed-precondition",
        "NO_QUESTIONS_AVAILABLE",
        {
          topic: resolved.canonicalTopicId,
          totalQuestions: 0,
          collection: "questions",
          testedFields: ["topicId", "categoryId"],
        }
      );
    }

    const poolIds = questionsSnap.docs.map((doc) => doc.id);
    poolSize = poolIds.length;
    if (poolSize < quizSize) {
      throw new HttpsError(
        "failed-precondition",
        "Not enough questions to create shared quiz"
      );
    }

    const seed = `shared-${resolved.canonicalTopicId}-${quizSize}`;
    selectedIds = seededShuffle(poolIds, seed).slice(0, quizSize);
    const questionById = new Map(
      questionsSnap.docs.map((doc) => [doc.id, doc])
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

  const topicStatsRef = db.doc(`users/${uid}/topicStats/${topicId}`);
  const topicStatsSnap = await topicStatsRef.get();

  const existingSeen: string[] =
    topicStatsSnap.exists &&
    Array.isArray(topicStatsSnap.data()?.seenQuestionIds)
      ? topicStatsSnap.data()!.seenQuestionIds
      : [];

  const updatedSeen = [...existingSeen, ...questionIds].slice(-200);

  const batch = db.batch();

  batch.update(playerRef, {
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    score,
    maxScore: questionIds.length,
    answers: scoredAnswers,
    locked: true,
  });

  batch.set(
    topicStatsRef,
    {
      seenQuestionIds: updatedSeen,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await batch.commit();

  const progressRef = db.doc(
    `users/${uid}/categoryProgress/${topicId}`
  );

  void (async () => {
    const progressSnap = await progressRef.get();
    const progressData = progressSnap.data() as
      | Partial<CategoryProgress>
      | undefined;
    const exhaustedCount = Number.isInteger(
      progressData?.exhaustedCount
    )
      ? (progressData!.exhaustedCount as number)
      : 0;
    const weekKey =
      typeof progressData?.weekKey === "string"
        ? progressData.weekKey
        : isoWeekKey();

    emitQuizAnalyticsEvent("quiz_completed", {
      categoryId: topicId,
      quizSize: questionIds.length,
      exhaustedCount,
      weekKey,
      mode: "solo",
      quizId: gameId,
    });
  })();

  return { score, maxScore: questionIds.length };
});

export * from "./quizSelection";
export * from "./admin/diagnostics";
