import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  buildTopicCandidates,
  resolveTopicId,
} from "../triviaQuestions";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

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

async function runDiagnostics(request: {
  auth?: { uid?: string; token?: Record<string, unknown> };
  data?: {
    topicId?: string;
    categoryId?: string;
    topic?: string;
    triviaPackId?: string;
  };
}) {
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

  const resolved = await resolveTopicId(db, topicId, categoryId, topic);
  const baseTopicId = resolved.canonicalTopicId;
  const candidateValues = buildTopicCandidates(resolved);

  const rootAttempts: Array<{
    field: string;
    value: string;
    count: number;
  }> = [];

  for (const field of ["topicId"] as const) {
    for (const value of candidateValues) {
      const rootCount = await db
        .collection("questions")
        .where(field, "==", value)
        .count()
        .get();
      rootAttempts.push({
        field,
        value,
        count: rootCount.data().count,
      });
    }
  }

  const fieldTotals = rootAttempts.reduce((acc, attempt) => {
    acc[attempt.field] = (acc[attempt.field] ?? 0) + attempt.count;
    return acc;
  }, {} as Record<string, number>);

  const samples: Record<string, string[]> = {};
  const sampleDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];
  for (const field of ["topicId"] as const) {
    const attempt = rootAttempts.find(
      (entry) => entry.field === field && entry.count > 0
    );
    if (!attempt) {
      samples[field] = [];
      continue;
    }
    const snap = await db
      .collection("questions")
      .where(field, "==", attempt.value)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(5)
      .get();
    samples[field] = snap.docs.map((doc) => doc.id);
    sampleDocs.push(...snap.docs);
  }

  let packInfo: Record<string, unknown> | null = null;
  if (typeof triviaPackId === "string" && triviaPackId.trim()) {
    const packSnap = await db
      .doc(`triviaPacks/${triviaPackId}`)
      .get();
    packInfo = packSnap.exists ? packSnap.data() ?? null : null;
  }

  logger.info("diagnoseTriviaTopic", {
    baseTopicId,
    counts: {
      fieldTotals,
    },
  });

  const warnings = collectMissingFieldWarnings(sampleDocs);

  const totalRoot = rootAttempts.reduce((sum, entry) => sum + entry.count, 0);
  let blockReason: string | null = null;
  if (totalRoot === 0) {
    blockReason = "no questions found for requested topic";
  }

  return {
    topicId: baseTopicId,
    inputTopicId: resolved.inputTopicId,
    inputCategoryId: resolved.inputCategoryId,
    inputTopic: resolved.inputTopic,
    resolvedFrom: resolved.resolvedFrom,
    mappingIssues: resolved.mappingIssues,
    candidateValues,
    counts: {
      rootAttempts,
      fieldTotals,
    },
    samples,
    missingFieldWarnings: warnings,
    blockReason,
    pack: packInfo,
  };
}

export const diagnoseTriviaTopic = onCall(async (request) => {
  return runDiagnostics(request);
});

export const diagnoseQuestionsForTopic = onCall(async (request) => {
  return runDiagnostics(request);
});
