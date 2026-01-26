import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";
import type { Firestore, QueryDocumentSnapshot } from "firebase-admin/firestore";

export interface TopicResolution {
  canonicalTopicId: string;
  inputTopicId?: string;
  inputCategoryId?: string;
  inputTopic?: string;
  resolvedFrom: string;
  mappingIssues: string[];
  categoryFallbackId?: string;
  normalizedTopicId: string;
}

export interface QuestionFetchResult {
  docs: QueryDocumentSnapshot[];
  questionIds: string[];
  totalQuestions: number;
  eligibleQuestions: number;
  topicId: string;
  normalizedTopicId: string;
  appliedFilters: {
    topicIdCandidates: string[];
    categoryId?: string;
  };
}

export interface TriviaPackGenerationResult {
  packId: string;
  topicId: string;
  questionIds: string[];
  questionDocs: QueryDocumentSnapshot[];
  appliedFilter: string;
  appliedValue?: string;
  totalQuestions: number;
}

export interface TriviaPackCreationResult {
  packId: string;
  topicId: string;
  questionIds: string[];
  questionDocs: QueryDocumentSnapshot[];
}

export function normalizeTopicKey(value: string): string {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_")
    .replace(/[^a-z0-9_]/g, "")
    .replace(/_+/g, "_");
}

function normalizeComparableId(value: string | undefined): string {
  return String(value || "").trim().toLowerCase();
}

function ensureValidTopicId(inputTopicId: string | undefined): {
  trimmedTopicId: string;
  normalizedTopicId: string;
} {
  const trimmedTopicId = typeof inputTopicId === "string" ? inputTopicId.trim() : "";
  if (!trimmedTopicId) {
    throw new HttpsError("invalid-argument", "Missing topicId");
  }
  const normalizedTopicId = normalizeComparableId(trimmedTopicId);
  return { trimmedTopicId, normalizedTopicId };
}

function collectCandidateValues(values: Array<string | undefined>): string[] {
  const set = new Set<string>();
  for (const value of values) {
    if (typeof value !== "string") continue;
    const trimmed = value.trim();
    if (!trimmed) continue;
    set.add(trimmed);
    const normalized = normalizeTopicKey(trimmed);
    if (normalized && normalized !== trimmed) {
      set.add(normalized);
    }
  }
  return Array.from(set);
}

function buildTopicQueryCandidates(topicId: string): string[] {
  return collectCandidateValues([topicId, normalizeComparableId(topicId)]);
}

export function buildTopicCandidates(resolved: TopicResolution): string[] {
  return collectCandidateValues([
    resolved.canonicalTopicId,
    resolved.normalizedTopicId,
    resolved.inputTopicId,
    resolved.inputCategoryId,
    resolved.inputTopic,
    resolved.categoryFallbackId,
  ]);
}

export async function resolveTopicId(
  db: Firestore,
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

  const normalizedInput = normalizeTopicKey(canonicalInput);
  const candidateIds = collectCandidateValues([
    canonicalInput,
    normalizedInput,
  ]);

  const mappingIssues: string[] = [];
  let resolvedFrom = "fallback";
  let canonicalTopicId = canonicalInput;
  let categoryFallbackId =
    inputCategoryId && inputCategoryId !== canonicalInput
      ? inputCategoryId
      : undefined;

  for (const candidate of candidateIds) {
    const [topicSnap, categorySnap] = await Promise.all([
      db.doc(`topics/${candidate}`).get(),
      db.doc(`categories/${candidate}`).get(),
    ]);

    if (topicSnap.exists) {
      resolvedFrom = "topics";
      canonicalTopicId = candidate;
      break;
    }

    if (categorySnap.exists) {
      resolvedFrom = "categories";
      const data = categorySnap.data() as { topicId?: string; id?: string };
      if (typeof data?.topicId === "string" && data.topicId.trim()) {
        canonicalTopicId = data.topicId.trim();
        categoryFallbackId = categoryFallbackId ?? inputCategoryId;
      } else if (typeof data?.id === "string" && data.id.trim()) {
        canonicalTopicId = data.id.trim();
      } else {
        canonicalTopicId = candidate;
      }
      break;
    }
  }

  if (
    normalizedInput &&
    normalizedInput !== canonicalInput &&
    canonicalTopicId === canonicalInput
  ) {
    canonicalTopicId = normalizedInput;
    mappingIssues.push("normalized topic fallback");
  }

  if (!canonicalTopicId) {
    canonicalTopicId = canonicalInput;
  }

  if (!candidateIds.includes(canonicalTopicId)) {
    mappingIssues.push("canonical topic not in candidates");
  }

  if (!candidateIds.length) {
    mappingIssues.push("no candidate topic ids");
  }

  if (inputCategoryId && inputTopicId && inputCategoryId !== inputTopicId) {
    categoryFallbackId = categoryFallbackId ?? inputCategoryId;
    mappingIssues.push("topicId and categoryId differ");
  }

  if (resolvedFrom === "fallback") {
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
    normalizedTopicId: normalizedInput || canonicalTopicId,
  };
}

function shuffleInPlace<T>(items: T[]): T[] {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}

export function selectRandomDocs<T>(items: T[], limit?: number): T[] {
  const shuffled = shuffleInPlace([...items]);
  if (typeof limit === "number" && limit > 0 && limit < shuffled.length) {
    return shuffled.slice(0, limit);
  }
  return shuffled;
}

export async function getRandomQuestionsForTopic(
  db: Firestore,
  options: {
    topicId: string;
    categoryId?: string;
    limit?: number;
  }
): Promise<QuestionFetchResult> {
  const { topicId, limit, categoryId } = options;
  const { trimmedTopicId, normalizedTopicId } = ensureValidTopicId(topicId);
  const normalizedCategoryId = normalizeComparableId(categoryId);
  const topicCandidates = buildTopicQueryCandidates(trimmedTopicId);
  const limitedCandidates = topicCandidates.slice(0, 10);
  const topicQuery =
    limitedCandidates.length > 1
      ? db.collection("questions").where("topicId", "in", limitedCandidates)
      : db.collection("questions").where("topicId", "==", limitedCandidates[0]);
  const querySnap = await topicQuery.get();
  const allDocs = querySnap.docs;
  const totalQuestions = allDocs.length;
  const eligibleDocs = allDocs.filter((doc) => {
    const data = doc.data() as { categoryId?: string; topicId?: string };
    const docTopicId = normalizeComparableId(data.topicId);
    if (docTopicId && docTopicId !== normalizedTopicId) {
      return false;
    }
    if (!normalizedCategoryId) {
      return true;
    }
    const docCategoryId = normalizeComparableId(data.categoryId);
    if (!docCategoryId) {
      return true;
    }
    return docCategoryId === normalizedCategoryId;
  });
  const eligibleQuestions = eligibleDocs.length;

  logger.info("triviaQuestions pool summary", {
    topicId: normalizedTopicId,
    inputTopicId: trimmedTopicId,
    appliedFilters: {
      topicIdCandidates: limitedCandidates,
      categoryId: normalizedCategoryId || undefined,
    },
    poolSize: totalQuestions,
    eligibleSize: eligibleQuestions,
  });

  if (eligibleQuestions === 0) {
    return {
      docs: [],
      questionIds: [],
      totalQuestions,
      eligibleQuestions,
      topicId: trimmedTopicId,
      normalizedTopicId,
      appliedFilters: {
        topicIdCandidates: limitedCandidates,
        categoryId: normalizedCategoryId || undefined,
      },
    };
  }
  const selectedDocs: QueryDocumentSnapshot[] = selectRandomDocs(
    eligibleDocs,
    limit
  );
  return {
    docs: selectedDocs,
    questionIds: selectedDocs.map((doc) => doc.id),
    totalQuestions,
    eligibleQuestions,
    topicId: trimmedTopicId,
    normalizedTopicId,
    appliedFilters: {
      topicIdCandidates: limitedCandidates,
      categoryId: normalizedCategoryId || undefined,
    },
  };
}

export async function generateTriviaPack(
  db: Firestore,
  options: {
    topicId: string;
    categoryId?: string;
    questionCount: number;
    createdBy: string;
  }
): Promise<TriviaPackGenerationResult> {
  const { trimmedTopicId, normalizedTopicId } = ensureValidTopicId(
    options.topicId
  );
  const questionResult = await getRandomQuestionsForTopic(db, {
    topicId: trimmedTopicId,
    categoryId: options.categoryId,
    limit: options.questionCount,
  });
  const questionDocs = questionResult.docs;
  if (questionResult.eligibleQuestions < options.questionCount) {
    throw new HttpsError(
      "failed-precondition",
      `Not enough questions for topic ${normalizedTopicId}. Found ${questionResult.eligibleQuestions}, need ${options.questionCount}.`,
      {
        code: "INSUFFICIENT_QUESTIONS",
        topicId: normalizedTopicId,
        requestedSize: options.questionCount,
        poolSize: questionResult.eligibleQuestions,
      }
    );
  }

  const selectedDocs = questionDocs;
  const questionIds = selectedDocs.map((doc) => doc.id);

  const packRef = db.collection("triviaPacks").doc();
  await packRef.set({
    id: packRef.id,
    topicId: trimmedTopicId,
    questionIds,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: options.createdBy,
    status: "active",
    version: 1,
  });

  return {
    packId: packRef.id,
    topicId: trimmedTopicId,
    questionIds,
    questionDocs: selectedDocs,
    appliedFilter: "topicId",
    appliedValue: trimmedTopicId,
    totalQuestions: questionResult.totalQuestions,
  };
}

export async function createTriviaPackFromDocs(
  db: Firestore,
  options: {
    topicId: string;
    questionDocs: QueryDocumentSnapshot[];
    createdBy: string;
  }
): Promise<TriviaPackCreationResult> {
  const trimmedTopicId = options.topicId.trim();
  if (!trimmedTopicId) {
    throw new HttpsError("invalid-argument", "Missing topicId");
  }
  const questionIds = options.questionDocs.map((doc) => doc.id);
  const packRef = db.collection("triviaPacks").doc();
  await packRef.set({
    id: packRef.id,
    topicId: trimmedTopicId,
    questionIds,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: options.createdBy,
    status: "active",
    version: 1,
  });

  return {
    packId: packRef.id,
    topicId: trimmedTopicId,
    questionIds,
    questionDocs: options.questionDocs,
  };
}
