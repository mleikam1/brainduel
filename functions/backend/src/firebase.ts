import { getFirestore } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";

let db: Firestore | null = null;

export const getDb = (): Firestore => {
  if (!db) {
    db = getFirestore();
  }
  return db;
};
