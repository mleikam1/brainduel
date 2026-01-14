/**
 * trivia_seed.js
 *
 * Ingests trivia_seed.json into Firestore with deterministic question IDs.
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

async function seed() {
  for (const topic of triviaData.topics) {
    const { id: categoryId, displayName, questions } = topic;

    const categoryRef = db.collection("categories").doc(categoryId);

    // Upsert category metadata
    await categoryRef.set(
      {
        id: categoryId,
        displayName,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log(`Seeding category: ${categoryId}`);

    for (const q of questions) {
      const questionId = generateQuestionId(
        categoryId,
        q.prompt,
        q.choices,
        q.correctIndex
      );

      const questionRef = categoryRef
        .collection("questions")
        .doc(questionId);

      await questionRef.set(
        {
          id: questionId,            // stored explicitly
          categoryId,
          prompt: q.prompt,
          choices: q.choices,
          correctIndex: q.correctIndex,
          difficulty: q.difficulty,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }
  }

  console.log("Trivia seeding complete.");
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
