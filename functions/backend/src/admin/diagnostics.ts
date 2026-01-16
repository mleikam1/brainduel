import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface TopicResolution {
  canonicalTopicId: string;
  inputTopicId?: string;
  inputCategoryId?: string;
  resolvedFrom: string;
  mappingIssues: string[];
}

async function resolveTopicId(
  topicId?: string,
  categoryId?: string
): Promise<TopicResolution> {
  const trimmedTopicId = typeof topicId === "string" ? topicId.trim() : "";
  const trimmedCategoryId =
    typeof categoryId === "string" ? categoryId.trim() : "";
  const inputTopicId = trimmedTopicId || undefined;
  const inputCategoryId = trimmedCategoryId || undefined;

  if (!inputTopicId && !inputCategoryId) {
    throw new HttpsError(
      "invalid-argument",
      "topicId or categoryId is required"
    );
  }

  const canonicalTopicId = inputTopicId ?? inputCategoryId!;
  const mappingIssues: string[] = [];
  let resolvedFrom = "fallback";

  const [topicSnap, categorySnap] = await Promise.all([
    db.doc(`topics/${canonicalTopicId}`).get(),
    db.doc(`categories/${canonicalTopicId}`).get(),
  ]);

  if (topicSnap.exists) {
    resolvedFrom = "topics";
  } else if (categorySnap.exists) {
    resolvedFrom = "categories";
  } else {
    mappingIssues.push("no matching topic/category doc");
  }

  return {
    canonicalTopicId,
    inputTopicId,
    inputCategoryId,
    resolvedFrom,
    mappingIssues,
  };
}

export const diagnoseQuestionsForTopic = onCall(async (request) => {
  const uid = request.auth?.uid;
  const isAdmin = request.auth?.token?.admin === true;
  const topicId = request.data?.topicId as string | undefined;
  const categoryId = request.data?.categoryId as string | undefined;
  const triviaPackId = request.data?.triviaPackId as string | undefined;

  if (!uid || !isAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Diagnostics access denied"
    );
  }

  const resolved = await resolveTopicId(topicId, categoryId);
  const baseTopicId = resolved.canonicalTopicId;

  const queries = {
    topicActive: db
      .collection("questions")
      .where("topicId", "==", baseTopicId)
      .where("active", "==", true),
    topicAny: db.collection("questions").where("topicId", "==", baseTopicId),
    categoryActive: db
      .collection("questions")
      .where("categoryId", "==", baseTopicId)
      .where("active", "==", true),
    categoryAny: db
      .collection("questions")
      .where("categoryId", "==", baseTopicId),
  };

  const [topicActiveCount, topicAnyCount, categoryActiveCount, categoryAnyCount] =
    await Promise.all([
      queries.topicActive.count().get(),
      queries.topicAny.count().get(),
      queries.categoryActive.count().get(),
      queries.categoryAny.count().get(),
    ]);

  const [topicSample, categorySample] = await Promise.all([
    queries.topicAny
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(5)
      .get(),
    queries.categoryAny
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(5)
      .get(),
  ]);

  let packInfo: Record<string, unknown> | null = null;
  if (typeof triviaPackId === "string" && triviaPackId.trim()) {
    const packSnap = await db
      .doc(`trivia_packs/${triviaPackId}`)
      .get();
    packInfo = packSnap.exists ? packSnap.data() ?? null : null;
  }

  logger.info("diagnoseQuestionsForTopic", {
    baseTopicId,
    counts: {
      topicActive: topicActiveCount.data().count,
      topicAny: topicAnyCount.data().count,
      categoryActive: categoryActiveCount.data().count,
      categoryAny: categoryAnyCount.data().count,
    },
  });

  return {
    topicId: baseTopicId,
    inputTopicId: resolved.inputTopicId,
    inputCategoryId: resolved.inputCategoryId,
    resolvedFrom: resolved.resolvedFrom,
    mappingIssues: resolved.mappingIssues,
    counts: {
      topicActive: topicActiveCount.data().count,
      topicAny: topicAnyCount.data().count,
      categoryActive: categoryActiveCount.data().count,
      categoryAny: categoryAnyCount.data().count,
    },
    samples: {
      topicIds: topicSample.docs.map((doc) => doc.id),
      categoryIds: categorySample.docs.map((doc) => doc.id),
    },
    pack: packInfo,
  };
});
