import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { emitQuizAnalyticsEvent } from "./analytics";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface CategoryProgress {
  seed: string;
  cursor: number;
  exhaustedCount: number;
  weekKey: string;
}

interface QuizSelectionResponse {
  questionIds: string[];
  selectionMeta: {
    exhaustedThisPick: boolean;
    weekKey: string;
    cursorBefore: number;
    cursorAfter: number;
    poolSize: number;
  };
}

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

export const selectQuizQuestions = onCall(async (request) => {
  const uid = request.auth?.uid;
  const categoryId = request.data?.categoryId as string | undefined;
  const quizSize = request.data?.quizSize as number | undefined;

  if (!uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  if (!categoryId || typeof quizSize !== "number" || quizSize <= 0) {
    throw new HttpsError(
      "invalid-argument",
      "categoryId and quizSize are required"
    );
  }

  const progressRef = db.doc(`users/${uid}/categoryProgress/${categoryId}`);
  const weekKey = isoWeekKey();

  const [progressSnap, questionsSnap] = await Promise.all([
    progressRef.get(),
    db
      .collection("questions")
      .where("topicId", "==", categoryId)
      .where("active", "==", true)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500)
      .get(),
  ]);

  if (questionsSnap.empty) {
    throw new HttpsError(
      "failed-precondition",
      "No questions available for category"
    );
  }

  const questionIds = questionsSnap.docs.map((doc) => doc.id);
  const poolSize = questionIds.length;

  if (poolSize < quizSize) {
    throw new HttpsError(
      "failed-precondition",
      "Not enough questions to create quiz"
    );
  }

  const progressData = progressSnap.data() as Partial<CategoryProgress> | undefined;
  const isSameWeek = progressData?.weekKey === weekKey;
  const seed =
    isSameWeek && typeof progressData?.seed === "string"
      ? progressData.seed
      : `${uid}-${categoryId}-${weekKey}`;
  const cursorStart = isSameWeek && Number.isInteger(progressData?.cursor)
    ? (progressData!.cursor as number)
    : 0;
  const exhaustedBase =
    isSameWeek && Number.isInteger(progressData?.exhaustedCount)
      ? (progressData!.exhaustedCount as number)
      : 0;

  const shuffledIds = seededShuffle(questionIds, seed);
  const cursorBefore = ((cursorStart % poolSize) + poolSize) % poolSize;
  const end = cursorBefore + quizSize;
  let selectedIds: string[] = [];
  let cursorAfter = 0;
  let exhaustedThisPick = false;

  if (end <= poolSize) {
    selectedIds = shuffledIds.slice(cursorBefore, end);
    cursorAfter = end === poolSize ? 0 : end;
    exhaustedThisPick = end === poolSize;
  } else {
    selectedIds = [
      ...shuffledIds.slice(cursorBefore),
      ...shuffledIds.slice(0, end - poolSize),
    ];
    cursorAfter = end - poolSize;
    exhaustedThisPick = true;
  }

  const exhaustedCount =
    exhaustedBase + (exhaustedThisPick ? 1 : 0);

  await progressRef.set(
    {
      seed,
      cursor: cursorAfter,
      exhaustedCount,
      weekKey,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  emitQuizAnalyticsEvent("quiz_started", {
    categoryId,
    quizSize,
    poolSize,
    exhaustedCount,
    weekKey,
    mode: "solo",
  });

  if (exhaustedThisPick) {
    emitQuizAnalyticsEvent("category_exhausted", {
      categoryId,
      quizSize,
      poolSize,
      exhaustedCount,
      weekKey,
      mode: "solo",
    });
  }

  const response: QuizSelectionResponse = {
    questionIds: selectedIds,
    selectionMeta: {
      exhaustedThisPick,
      weekKey,
      cursorBefore,
      cursorAfter,
      poolSize,
    },
  };

  return response;
});
