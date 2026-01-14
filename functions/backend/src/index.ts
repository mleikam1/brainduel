import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

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

/**
 * Callable: createGame
 */
export const createGame = onCall(async (request) => {
  const uid = request.auth?.uid;
  const topicId = request.data?.topicId as string | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  if (!topicId) {
    throw new HttpsError("invalid-argument", "topicId is required");
  }

  const progressRef = db.doc(
    `users/${uid}/categoryProgress/${topicId}`
  );

  const questionsSnap = await db
    .collection("questions")
    .where("topicId", "==", topicId)
    .where("active", "==", true)
    .limit(200)
    .get();

  if (questionsSnap.empty) {
    throw new HttpsError(
      "failed-precondition",
      "No questions available for topic"
    );
  }

  const allQuestions: QuestionDoc[] = questionsSnap.docs.map((d) => {
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
      : `${uid}-${topicId}-${weekKey}`;
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
    throw new HttpsError(
      "failed-precondition",
      "Not enough questions to create game"
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
    throw new HttpsError(
      "failed-precondition",
      "Not enough questions to create game"
    );
  }

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
    topicId,
    createdByUid: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: "open",
    questionIds: selected.map((q) => q.id),
    questionsSnapshot,
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

  return {
    gameId,
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

  return { score, maxScore: questionIds.length };
});
