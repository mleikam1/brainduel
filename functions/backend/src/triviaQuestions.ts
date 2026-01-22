import { HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import type { FirebaseFirestore } from "firebase-admin";

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
  docs: FirebaseFirestore.QueryDocumentSnapshot[];
  questionIds: string[];
  totalQuestions: number;
  topicId: string;
}

export interface TriviaPackGenerationResult {
  packId: string;
  topicId: string;
  questionIds: string[];
  questionDocs: FirebaseFirestore.QueryDocumentSnapshot[];
  appliedFilter: string;
  appliedValue?: string;
  totalQuestions: number;
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

function shuffleInPlace<T>(items: T[]): T[] {
  for (let i = items.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [items[i], items[j]] = [items[j], items[i]];
  }
  return items;
}

export async function getRandomQuestionsForTopic(
  db: FirebaseFirestore.Firestore,
  options: {
    topicId: string;
    limit?: number;
  }
): Promise<QuestionFetchResult> {
  const { topicId, limit } = options;
  // Questions are stored with string topicId/categoryId fields; query only topicId for gameplay selection.
  const querySnap = await db
    .collection("questions")
    .where("topicId", "==", topicId)
    .get();
  const allDocs = querySnap.docs;
  const totalQuestions = allDocs.length;
  if (totalQuestions === 0) {
    return {
      docs: [],
      questionIds: [],
      totalQuestions,
      topicId,
    };
  }
  const shuffledDocs = shuffleInPlace([...allDocs]);
  const selectedDocs =
    typeof limit === "number" && limit > 0 && limit < shuffledDocs.length
      ? shuffledDocs.slice(0, limit)
      : shuffledDocs;
  return {
    docs: selectedDocs,
    questionIds: selectedDocs.map((doc) => doc.id),
    totalQuestions,
    topicId,
  };
}

export async function generateTriviaPack(
  db: FirebaseFirestore.Firestore,
  options: {
    topicId: string;
    questionCount: number;
    createdBy: string;
  }
): Promise<TriviaPackGenerationResult> {
  const trimmedTopicId = options.topicId.trim();
  if (!trimmedTopicId) {
    throw new HttpsError("invalid-argument", "Missing topicId");
  }
  const questionResult = await getRandomQuestionsForTopic(db, {
    topicId: trimmedTopicId,
    limit: options.questionCount,
  });
  const questionDocs = questionResult.docs;
  if (questionDocs.length === 0) {
    throw new HttpsError("failed-precondition", "No questions available");
  }

  const selectedDocs = questionDocs;
  const questionIds = selectedDocs.map((doc) => doc.id);

  const packRef = db.collection("trivia_packs").doc();
  await packRef.set({
    id: packRef.id,
    topicId: trimmedTopicId,
    questionIds,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: options.createdBy,
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
