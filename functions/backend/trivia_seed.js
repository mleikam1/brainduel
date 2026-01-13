/* eslint-disable no-console */
"use strict";

/**
 * Firestore Trivia Seeder
 *
 * Safe, idempotent ingestion of topics + questions.
 *
 * - Does NOT deploy or modify Cloud Functions
 * - Uses deterministic IDs to prevent duplicates
 * - Validates schema before writing
 * - Batched writes (<= 450 ops per batch)
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/serviceAccount.json"
 *   node functions/backend/trivia_seed.js functions/backend/trivia_seed.json
 */

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const admin = require("firebase-admin");

/* ----------------------- helpers ----------------------- */

function die(message) {
  console.error(`❌ ${message}`);
  process.exit(1);
}

function sha1(input) {
  return crypto.createHash("sha1").update(input).digest("hex");
}

function normalizeTopicId(id) {
  return String(id)
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

function loadJson(filePath) {
  if (!fs.existsSync(filePath)) {
    die(`Seed file not found: ${filePath}`);
  }
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function validateSeed(seed) {
  if (!seed || !Array.isArray(seed.topics)) {
    die("Seed file must contain a top-level 'topics' array");
  }

  seed.topics.forEach((topic, tIndex) => {
    if (!topic.id || !topic.displayName) {
      die(`Topic at index ${tIndex} must have id and displayName`);
    }

    if (!Array.isArray(topic.questions)) {
      die(`Topic '${topic.id}' must contain a questions array`);
    }

    topic.questions.forEach((q, qIndex) => {
      if (!q.prompt || typeof q.prompt !== "string") {
        die(`Missing prompt in topic '${topic.id}', question ${qIndex}`);
      }

      if (!Array.isArray(q.choices) || q.choices.length !== 4) {
        die(`Question '${q.prompt}' must have exactly 4 choices`);
      }

      if (
        !Number.isInteger(q.correctIndex) ||
        q.correctIndex < 0 ||
        q.correctIndex > 3
      ) {
        die(`Invalid correctIndex for question '${q.prompt}'`);
      }

      if (
        q.difficulty &&
        !["easy", "medium", "hard"].includes(q.difficulty)
      ) {
        die(`Invalid difficulty for question '${q.prompt}'`);
      }
    });
  });
}

/* ----------------------- main ----------------------- */

async function main() {
  const seedArg = process.argv[2];
  if (!seedArg) {
    die("Usage: node trivia_seed.js path/to/trivia_seed.json");
  }

  const seedPath = path.resolve(process.cwd(), seedArg);
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!credentialsPath) {
    die("GOOGLE_APPLICATION_CREDENTIALS env var is not set");
  }

  if (!fs.existsSync(credentialsPath)) {
    die(`Service account file not found: ${credentialsPath}`);
  }

  const seed = loadJson(seedPath);
  validateSeed(seed);

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }

  const db = admin.firestore();
  const topicsCol = db.collection("topics");
  const questionsCol = db.collection("questions");

  let batch = db.batch();
  let opCount = 0;

  let topicsWritten = 0;
  let questionsWritten = 0;

  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const topic of seed.topics) {
    const topicId = normalizeTopicId(topic.id);

    const topicRef = topicsCol.doc(topicId);
    batch.set(
      topicRef,
      {
        id: topicId,
        displayName: topic.displayName,
        active: true,
        createdAt: now,
        updatedAt: now,
      },
      { merge: true }
    );

    topicsWritten++;
    opCount++;

    for (const q of topic.questions) {
      const docId = sha1(`${topicId}|${q.prompt.trim()}`);
      const questionRef = questionsCol.doc(docId);

      batch.set(
        questionRef,
        {
          topicId,
          prompt: q.prompt.trim(),
          choices: q.choices.map((c) => c.trim()),
          correctIndex: q.correctIndex,
          difficulty: q.difficulty || "medium",
          active: true,
          createdAt: now,
          updatedAt: now,
        },
        { merge: true }
      );

      questionsWritten++;
      opCount++;

      if (opCount >= 450) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
        console.log("✅ Batch committed");
      }
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  console.log("🎉 Trivia seeding complete");
  console.log(`Topics upserted: ${topicsWritten}`);
  console.log(`Questions upserted: ${questionsWritten}`);
  console.log("Your existing createGame function will now use this data.");
}

main().catch((err) => {
  console.error("❌ Seeding failed:", err);
  process.exit(1);
});
