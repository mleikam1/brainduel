import * as admin from "firebase-admin";

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
