import * as admin from "firebase-admin";

export type QuizAnalyticsMode = "solo" | "shared";

export interface QuizAnalyticsParams {
  categoryId: string;
  quizSize: number;
  poolSize?: number | null;
  exhaustedCount: number;
  weekKey: string;
  mode: QuizAnalyticsMode;
  quizId?: string;
}

export function emitQuizAnalyticsEvent(
  eventName: string,
  params: QuizAnalyticsParams
): void {
  void Promise.resolve()
    .then(() => {
      const analytics = (admin as { analytics?: () => unknown }).analytics?.();
      const logEvent = (analytics as { logEvent?: (name: string, data: QuizAnalyticsParams) => Promise<void> | void })
        ?.logEvent;
      if (typeof logEvent === "function") {
        const result = logEvent(eventName, params);
        if (result && typeof (result as Promise<void>).catch === "function") {
          (result as Promise<void>).catch((error) => {
            console.warn("analytics_event_failed", {
              eventName,
              error,
            });
          });
        }
        return;
      }
      console.info("analytics_event", { eventName, params });
    })
    .catch((error) => {
      console.warn("analytics_event_failed", { eventName, error });
    });
}
