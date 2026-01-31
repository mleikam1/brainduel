import * as admin from "firebase-admin";

// Keep module initialization side-effect free for Firebase deploys.
admin.initializeApp();

export {
  challenge,
  completeGame,
  createGame,
  createSharedQuiz,
  getSharedQuiz,
  getTriviaPack,
  getWeekKey,
  loadGame,
  submitSoloScore,
} from "./cloudFunctions";
export { selectQuizQuestions } from "./quizSelection";
export {
  diagnoseQuestionsForTopic,
  diagnoseTriviaTopic,
} from "./admin/diagnostics";
