/**
 * trivia_seed.js
 *
 * Ingests trivia_seed.json into Firestore with deterministic question IDs.
 * NOTE: Uses the canonical root collections (topics + questions).
 */

const admin = require("firebase-admin");
const crypto = require("crypto");
const triviaData = require("./trivia_seed.json");

admin.initializeApp();
const db = admin.firestore();

/**
 * Generate a stable question ID.
 */
function generateQuestionId(categoryId, prompt, choices, correctIndex) {
  const base = `${categoryId}||${prompt}||${choices.join("|")}||${correctIndex}`;
  return crypto
    .createHash("sha1")
    .update(base, "utf8")
    .digest("hex")
    .slice(0, 16); // short but safe
}

function normalizeTopicId(id) {
  return String(id || "")
    .trim()
    .toLowerCase()
    .replace(/[\s-]+/g, "_")
    .replace(/[^a-z0-9_]/g, "")
    .replace(/_+/g, "_");
}

async function seed() {
  let topicCount = 0;
  let questionCount = 0;
  for (const topic of triviaData.topics) {
    const { id: rawId, displayName, questions } = topic;
    const categoryId = normalizeTopicId(rawId);

    const topicRef = db.collection("topics").doc(categoryId);

    // Upsert topic metadata
    await topicRef.set(
      {
        id: categoryId,
        displayName,
        active: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log(`Seeding topic: ${categoryId}`);
    topicCount++;
    let topicQuestions = 0;

    for (const q of questions) {
      const questionId = generateQuestionId(
        categoryId,
        q.prompt,
        q.choices,
        q.correctIndex
      );

      const questionRef = db.collection("questions").doc(questionId);

      await questionRef.set(
        {
          id: questionId,            // stored explicitly
          categoryId,
          topicId: categoryId,
          prompt: q.prompt,
          choices: q.choices,
          correctIndex: q.correctIndex,
          difficulty: q.difficulty,
          active: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      topicQuestions++;
      questionCount++;
    }
    console.log(`Topic ${categoryId}: ${topicQuestions} questions`);
  }

  console.log(
    `Trivia seeding complete. Upserted topics: ${topicCount}, questions: ${questionCount}`
  );
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
