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
  inputTopic?: string;
  resolvedFrom: string;
  mappingIssues: string[];
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

  const canonicalTopicId = canonicalInput;
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
    inputTopic,
    resolvedFrom,
    mappingIssues,
  };
}

function collectMissingFieldWarnings(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): string[] {
  const warnings = new Set<string>();
  for (const doc of docs) {
    const data = doc.data() as {
      topicId?: string;
      categoryId?: string;
      prompt?: string;
      choices?: unknown;
      correctIndex?: number;
    };
    if (typeof data.topicId !== "string" || !data.topicId.trim()) {
      warnings.add("missing topicId");
    }
    if (typeof data.categoryId !== "string" || !data.categoryId.trim()) {
      warnings.add("missing categoryId");
    }
    if (typeof data.prompt !== "string" || !data.prompt.trim()) {
      warnings.add("missing prompt");
    }
    if (!Array.isArray(data.choices) || data.choices.length === 0) {
      warnings.add("missing choices");
    }
    if (!Number.isInteger(data.correctIndex)) {
      warnings.add("missing correctIndex");
    }
  }
  return Array.from(warnings);
}

export const diagnoseQuestionsForTopic = onCall(async (request) => {
  const uid = request.auth?.uid;
  const isAdmin = request.auth?.token?.admin === true;
  const topicId = request.data?.topicId as string | undefined;
  const categoryId = request.data?.categoryId as string | undefined;
  const topic = request.data?.topic as string | undefined;
  const triviaPackId = request.data?.triviaPackId as string | undefined;

  if (!uid || !isAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Diagnostics access denied"
    );
  }

  const resolved = await resolveTopicId(topicId, categoryId, topic);
  const baseTopicId = resolved.canonicalTopicId;

  const queries = {
    topicAny: db.collection("questions").where("topicId", "==", baseTopicId),
    categoryAny: db.collection("questions").where("categoryId", "==", baseTopicId),
  };

  const [topicAnyCount, categoryAnyCount] = await Promise.all([
    queries.topicAny.count().get(),
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
      topicAny: topicAnyCount.data().count,
      categoryAny: categoryAnyCount.data().count,
    },
  });

  const warnings = collectMissingFieldWarnings([
    ...topicSample.docs,
    ...categorySample.docs,
  ]);

  return {
    topicId: baseTopicId,
    inputTopicId: resolved.inputTopicId,
    inputCategoryId: resolved.inputCategoryId,
    inputTopic: resolved.inputTopic,
    resolvedFrom: resolved.resolvedFrom,
    mappingIssues: resolved.mappingIssues,
    counts: {
      topicAny: topicAnyCount.data().count,
      categoryAny: categoryAnyCount.data().count,
    },
    samples: {
      topicIds: topicSample.docs.map((doc) => doc.id),
      categoryIds: categorySample.docs.map((doc) => doc.id),
    },
    missingFieldWarnings: warnings,
    pack: packInfo,
  };
});
