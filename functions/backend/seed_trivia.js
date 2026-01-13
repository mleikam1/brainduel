/* eslint-disable no-console */
"use strict";

/**
 * One-time (or occasional) Firestore seeding script for topics + questions.
 *
 * Safe by design:
 * - Does NOT modify Cloud Functions.
 * - Idempotent: uses deterministic document IDs (hash of topicId|prompt).
 * - No duplicate questions: same prompt in same topic maps to same doc ID.
 * - Uses batched writes (<= 450 ops per batch).
 *
 * Required env var:
 *   GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/serviceAccountKey.json
 *
 * Usage:
 *   node functions/backend/seed_trivia.js functions/backend/trivia_seed.json
 */

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const admin = require("firebase-admin");

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

function sha1(input) {
  return crypto.createHash("sha1").update(input).digest("hex");
}

function normalizeTopicId(id) {
  return String(id || "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function loadJson(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  return JSON.parse(raw);
}

function validateSeed(seed) {
  assert(seed && typeof seed === "object", "Seed file must be a JSON object");
  assert(Array.isArray(seed.topics), "Seed must contain topics[]");

  // Seed topics are the category registry; normalized topicId must match
  // frontend categoryId values to keep Home/Discover/Rankings aligned.
  seed.topics.forEach((t, idx) => {
    const topicId = normalizeTopicId(t.id);
    assert(topicId, `topics[${idx}].id is required`);
    assert(
      typeof t.displayName === "string" && t.displayName.trim().length > 0,
      `topics[${idx}].displayName is required`
    );
    assert(Array.isArray(t.questions), `topics[${idx}].questions must be an array`);

    t.questions.forEach((q, qIdx) => {
      assert(
        typeof q.prompt === "string" && q.prompt.trim().length > 0,
        `topics[${idx}].questions[${qIdx}].prompt is required`
      );
      assert(
        Array.isArray(q.choices) && q.choices.length === 4,
        `topics[${idx}].questions[${qIdx}].choices must have exactly 4 items`
      );
      q.choices.forEach((c, cIdx) => {
        assert(
          typeof c === "string" && c.trim().length > 0,
          `topics[${idx}].questions[${qIdx}].choices[${cIdx}] must be a non-empty string`
        );
      });

      assert(
        Number.isInteger(q.correctIndex) && q.correctIndex >= 0 && q.correctIndex <= 3,
        `topics[${idx}].questions[${qIdx}].correctIndex must be 0..3`
      );

      if (q.difficulty != null) {
        assert(
          ["easy", "medium", "hard"].includes(q.difficulty),
          `topics[${idx}].questions[${qIdx}].difficulty must be easy|medium|hard`
        );
      }
    });
  });
}

async function main() {
  const inputArg = process.argv[2];
  assert(
    inputArg,
    "Missing seed file path.\nUsage: node functions/backend/seed_trivia.js functions/backend/trivia_seed.json"
  );

  const seedPath = path.resolve(process.cwd(), inputArg);
  assert(fs.existsSync(seedPath), `Seed file not found: ${seedPath}`);

  // Ensure credentials are available
  const credsPath = requireEnv("GOOGLE_APPLICATION_CREDENTIALS");
  assert(fs.existsSync(credsPath), `Service account file not found: ${credsPath}`);

  // Init Admin SDK using the service account from env var
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }

  const db = admin.firestore();
  const seed = loadJson(seedPath);

  validateSeed(seed);

  const topicsCol = db.collection("topics");
  const questionsCol = db.collection("questions");

  let batch = db.batch();
  let ops = 0;

  let topicCount = 0;
  let questionCount = 0;

  const now = admin.firestore.FieldValue.serverTimestamp();

  // Each topicId becomes the categoryId used when querying questions by topicId.
  // Add new categories by appending topics in trivia_seed.json and re-running.
  for (const t of seed.topics) {
    const topicId = normalizeTopicId(t.id);
    const displayName = t.displayName.trim();

    // Upsert topic doc by id
    const topicRef = topicsCol.doc(topicId);
    batch.set(
      topicRef,
      {
        id: topicId,
        displayName,
        active: true,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true }
    );

    ops++;
    topicCount++;

    // Questions: deterministic docId = sha1(topicId|prompt)
    for (const q of t.questions) {
      const prompt = q.prompt.trim();
      const docId = sha1(`${topicId}|${prompt}`);

      const questionRef = questionsCol.doc(docId);

      const difficulty = q.difficulty || "medium";

      batch.set(
        questionRef,
        {
          topicId,
          prompt,
          choices: q.choices.map((c) => String(c).trim()),
          correctIndex: q.correctIndex,
          difficulty,
          active: true,
          updatedAt: now,
          createdAt: now,
        },
        { merge: true }
      );

      ops++;
      questionCount++;

      // Firestore batch limit is 500 ops; stay comfortably under
      if (ops >= 450) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
        console.log("Committed batch...");
      }
    }
  }

  if (ops > 0) {
    await batch.commit();
    console.log("Committed final batch...");
  }

  console.log(`Done. Upserted topics: ${topicCount}, questions: ${questionCount}`);
  console.log("Your deployed createGame will immediately start using these questions.");
}

main().catch((err) => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
