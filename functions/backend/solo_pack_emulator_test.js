/* eslint-disable no-console */
"use strict";

const admin = require("firebase-admin");
const projectId = process.env.FIREBASE_PROJECT_ID || "demo-brain-duel";
const emulatorHost = process.env.FIREBASE_EMULATOR_HOST || "127.0.0.1";
const functionsPort = Number(process.env.FUNCTIONS_EMULATOR_PORT || 5001);
const firestorePort = Number(process.env.FIRESTORE_EMULATOR_PORT || 8080);
const authPort = Number(process.env.FIREBASE_AUTH_EMULATOR_PORT || 9099);

process.env.FIRESTORE_EMULATOR_HOST = `${emulatorHost}:${firestorePort}`;
process.env.FIREBASE_AUTH_EMULATOR_HOST = `${emulatorHost}:${authPort}`;

admin.initializeApp({ projectId });
const db = admin.firestore();

const sampleQuestions = [
  {
    prompt: "How many players are on the field for one soccer team during regulation play?",
    choices: ["9", "10", "11", "12"],
    correctIndex: 2,
    difficulty: "easy",
  },
  {
    prompt: "In basketball, how many points is a free throw worth?",
    choices: ["1", "2", "3", "4"],
    correctIndex: 0,
    difficulty: "easy",
  },
  {
    prompt: "Which sport uses the terms 'strike' and 'ball'?",
    choices: ["Baseball", "Hockey", "Tennis", "Rugby"],
    correctIndex: 0,
    difficulty: "easy",
  },
  {
    prompt: "How long is a standard NFL field including end zones?",
    choices: ["100 yards", "110 yards", "120 yards", "130 yards"],
    correctIndex: 2,
    difficulty: "easy",
  },
  {
    prompt: "What is the term for three strikes in bowling?",
    choices: ["Spare", "Turkey", "Ace", "Hat trick"],
    correctIndex: 1,
    difficulty: "easy",
  },
  {
    prompt: "How many players are on a volleyball team on the court?",
    choices: ["4", "5", "6", "7"],
    correctIndex: 2,
    difficulty: "easy",
  },
  {
    prompt: "In tennis, what is a score of 40-40 called?",
    choices: ["Deuce", "Advantage", "Love", "Match point"],
    correctIndex: 0,
    difficulty: "medium",
  },
  {
    prompt: "How many periods are in a standard ice hockey game?",
    choices: ["2", "3", "4", "5"],
    correctIndex: 1,
    difficulty: "medium",
  },
  {
    prompt: "Which country hosts the Tour de France?",
    choices: ["Spain", "Italy", "France", "Belgium"],
    correctIndex: 2,
    difficulty: "medium",
  },
  {
    prompt: "What is the maximum score possible in a single frame of bowling?",
    choices: ["20", "25", "30", "40"],
    correctIndex: 2,
    difficulty: "medium",
  },
];

async function seedSportsQuestions() {
  const topicId = "sports";
  await db.collection("topics").doc(topicId).set(
    {
      id: topicId,
      displayName: "Sports",
      active: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const batch = db.batch();
  sampleQuestions.forEach((question, index) => {
    const docId = `${topicId}_${index + 1}`;
    const ref = db.collection("questions").doc(docId);
    batch.set(
      ref,
      {
        id: docId,
        topicId,
        categoryId: topicId,
        prompt: question.prompt,
        choices: question.choices,
        correctIndex: question.correctIndex,
        difficulty: question.difficulty,
        active: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
  await batch.commit();
}

async function getIdToken(uid) {
  const customToken = await admin.auth().createCustomToken(uid);
  const response = await fetch(
    `http://${emulatorHost}:${authPort}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    }
  );
  if (!response.ok) {
    throw new Error(`Auth emulator sign-in failed: ${response.statusText}`);
  }
  const data = await response.json();
  return data.idToken;
}

async function callCallable(functionName, data, idToken) {
  const response = await fetch(
    `http://${emulatorHost}:${functionsPort}/${projectId}/us-central1/${functionName}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({ data }),
    }
  );
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Callable ${functionName} failed: ${errorText}`);
  }
  const payload = await response.json();
  return payload.result || payload.data || payload;
}

async function run() {
  console.log("Seeding sports questions...");
  await seedSportsQuestions();

  const tokenA = await getIdToken("tester-alpha");

  console.log("Calling createGame(sports)...");
  const createData = await callCallable(
    "createGame",
    { topicId: "sports", mode: "solo" },
    tokenA
  );
  const triviaPackId = createData.triviaPackId;
  const questionIds = createData.questionIds;

  if (!triviaPackId) {
    throw new Error("createGame did not return triviaPackId.");
  }
  if (!Array.isArray(questionIds) || questionIds.length !== 10) {
    throw new Error(`Expected 10 questionIds, got ${questionIds?.length ?? 0}.`);
  }

  console.log("Calling getTriviaPack...");
  const packData = await callCallable("getTriviaPack", { triviaPackId }, tokenA);
  const packQuestionIds = packData.questionIds;
  if (!Array.isArray(packQuestionIds) || packQuestionIds.length !== 10) {
    throw new Error("getTriviaPack returned invalid questionIds.");
  }
  if (packQuestionIds.join(",") !== questionIds.join(",")) {
    throw new Error("getTriviaPack question order does not match createGame.");
  }

  console.log("Submitting scores...");
  const answers = packQuestionIds.map((id) => ({
    questionId: id,
    selectedIndex: 0,
  }));
  const submitA = await callCallable(
    "submitSoloScore",
    { triviaPackId, score: 0, answers, metadata: { durationSeconds: 42 } },
    tokenA
  );
  console.log("Leaderboard after first score:", submitA.leaderboard);

  const tokenB = await getIdToken("tester-bravo");
  const submitB = await callCallable(
    "submitSoloScore",
    { triviaPackId, score: 0, answers, metadata: { durationSeconds: 55 } },
    tokenB
  );
  console.log("Leaderboard after second score:", submitB.leaderboard);

  console.log("✅ Emulator test completed.");
}

run().catch((err) => {
  console.error("Emulator test failed:", err);
  process.exit(1);
});
