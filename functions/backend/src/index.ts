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

  const topicStatsRef = db.doc(`users/${uid}/topicStats/${topicId}`);
  const topicStatsSnap = await topicStatsRef.get();

  const seenQuestionIds: string[] =
    topicStatsSnap.exists &&
    Array.isArray(topicStatsSnap.data()?.seenQuestionIds)
      ? topicStatsSnap.data()!.seenQuestionIds
      : [];

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

  const unseen = allQuestions.filter(
    (q) => !seenQuestionIds.includes(q.id)
  );

  const gameId = db.collection("games").doc().id;

  const selected = seededShuffle(
    unseen.length >= 10 ? unseen : allQuestions,
    gameId
  ).slice(0, 10);

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

  await batch.commit();

  return { gameId, questionsSnapshot };
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
