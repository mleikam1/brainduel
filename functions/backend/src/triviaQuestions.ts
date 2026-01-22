import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/logger";
import * as admin from "firebase-admin";
import type { FirebaseFirestore } from "firebase-admin";

export const QUESTION_FIELDS = [
  "topicId",
  "categoryId",
  "topic",
  "category",
] as const;

export type QuestionField = (typeof QUESTION_FIELDS)[number];

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

export interface QuestionQueryAttempt {
  field: QuestionField;
  value: string;
  count: number;
}

export interface QuestionFetchResult {
  docs: FirebaseFirestore.QueryDocumentSnapshot[];
  appliedFilter: string;
  appliedValue?: string;
  attempts: QuestionQueryAttempt[];
  candidateValues: string[];
  fieldsTested: QuestionField[];
  queryLimit: number;
  collection: string;
}

export interface TriviaPackGenerationResult {
  packId: string;
  topicId: string;
  questionIds: string[];
  questionDocs: FirebaseFirestore.QueryDocumentSnapshot[];
  appliedFilter: string;
  appliedValue?: string;
  totalQuestions: number;
  attempts: QuestionQueryAttempt[];
  queryLimit: number;
}

export function normalizeTopicKey(value: string): string {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_")
    .replace(/[^a-z0-9_]/g, "")
    .replace(/_+/g, "_");
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
  db: FirebaseFirestore.Firestore,
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

export async function getQuestionsForTopic(
  db: FirebaseFirestore.Firestore,
  options: {
    resolved: TopicResolution;
    count: number;
    limit?: number;
  }
): Promise<QuestionFetchResult> {
  const { resolved, count, limit } = options;
  const candidateValues = buildTopicCandidates(resolved);
  const fieldsTested = [...QUESTION_FIELDS];
  const queryLimit = Math.max(limit ?? count * 6, count);
  const attempts: QuestionQueryAttempt[] = [];

  for (const field of fieldsTested) {
    for (const value of candidateValues) {
      const query = db.collection("questions").where(field, "==", value);
      const countSnap = await query.count().get();
      const total = countSnap.data().count;
      attempts.push({ field, value, count: total });
      logger.info("question query attempt", {
        field,
        value,
        count: total,
        limit: queryLimit,
      });
      if (total > 0) {
        const docsSnap = await query.limit(queryLimit).get();
        return {
          docs: docsSnap.docs,
          appliedFilter: field,
          appliedValue: value,
          attempts,
          candidateValues,
          fieldsTested,
          queryLimit,
          collection: "questions",
        };
      }
    }
  }

  return {
    docs: [],
    appliedFilter: "none",
    attempts,
    candidateValues,
    fieldsTested,
    queryLimit,
    collection: "questions",
  };
}

function shuffleInPlace<T>(items: T[]): T[] {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}

async function findQuestionQueryForTopic(
  db: FirebaseFirestore.Firestore,
  resolved: TopicResolution,
  count: number
): Promise<{
  query: FirebaseFirestore.Query;
  appliedFilter: string;
  appliedValue: string;
  attempts: QuestionQueryAttempt[];
  queryLimit: number;
}> {
  const candidateValues = buildTopicCandidates(resolved);
  const fieldsTested = [...QUESTION_FIELDS];
  const queryLimit = Math.max(count * 6, count);
  const attempts: QuestionQueryAttempt[] = [];

  for (const field of fieldsTested) {
    for (const value of candidateValues) {
      const query = db.collection("questions").where(field, "==", value);
      const countSnap = await query.count().get();
      const total = countSnap.data().count;
      attempts.push({ field, value, count: total });
      logger.info("question query attempt", {
        field,
        value,
        count: total,
        limit: queryLimit,
      });
      if (total > 0) {
        return {
          query,
          appliedFilter: field,
          appliedValue: value,
          attempts,
          queryLimit,
        };
      }
    }
  }

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
      fieldsTested,
      candidateValues,
      queryLimit,
      attempts,
    }
  );
}

export async function generateTriviaPack(
  db: FirebaseFirestore.Firestore,
  options: {
    topicId: string;
    questionCount: number;
    createdBy: string;
  }
): Promise<TriviaPackGenerationResult> {
  const resolved = await resolveTopicId(db, options.topicId);
  const queryResult = await findQuestionQueryForTopic(
    db,
    resolved,
    options.questionCount
  );

  const questionSnap = await queryResult.query.get();
  const questionDocs = questionSnap.docs;
  if (questionDocs.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "NO_QUESTIONS_EXIST_FOR_TOPIC",
      {
        code: "NO_QUESTIONS_EXIST_FOR_TOPIC",
        topic: resolved.canonicalTopicId,
      }
    );
  }

  const shuffledDocs = shuffleInPlace([...questionDocs]);
  const selectedDocs =
    options.questionCount >= shuffledDocs.length
      ? shuffledDocs
      : shuffledDocs.slice(0, options.questionCount);
  const questionIds = selectedDocs.map((doc) => doc.id);

  const packRef = db.collection("trivia_packs").doc();
  await packRef.set({
    id: packRef.id,
    topicId: resolved.canonicalTopicId,
    questionIds,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: options.createdBy,
  });

  return {
    packId: packRef.id,
    topicId: resolved.canonicalTopicId,
    questionIds,
    questionDocs: selectedDocs,
    appliedFilter: queryResult.appliedFilter,
    appliedValue: queryResult.appliedValue,
    totalQuestions: questionDocs.length,
    attempts: queryResult.attempts,
    queryLimit: queryResult.queryLimit,
  };
}
