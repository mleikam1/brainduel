import { onCall, HttpsError } from "firebase-functions/v2/https";
import { resolveTopicId, generateTriviaPack } from "./triviaQuestions";
import { getDb } from "./firebase";

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
  const db = getDb();
  const uid = request.auth?.uid;
  const categoryId = request.data?.categoryId as string | undefined;
  const topicId = request.data?.topicId as string | undefined;
  const topic = request.data?.topic as string | undefined;
  const quizSize = request.data?.quizSize as number | undefined;

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
  const canonicalTopicId = resolved.canonicalTopicId;
  const packResult = await generateTriviaPack(db, {
    topicId: canonicalTopicId,
    questionCount: quizSize,
    createdBy: uid,
  });
  const questionIds = packResult.questionIds;
  const poolSize = packResult.totalQuestions;

  const response: QuizSelectionResponse = {
    questionIds,
    selectionMeta: {
      exhaustedThisPick: false,
      weekKey: isoWeekKey(),
      cursorBefore: 0,
      cursorAfter: 0,
      poolSize,
    },
  };

  return response;
});
