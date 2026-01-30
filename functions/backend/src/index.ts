import * as admin from "firebase-admin";

admin.initializeApp();

export * from "./cloudFunctions";
export * from "./quizSelection";
export * from "./admin/diagnostics";
