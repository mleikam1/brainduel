import 'analytics_service.dart';

class QuizAnalyticsHelper {
  QuizAnalyticsHelper(this._analytics);

  final AnalyticsService _analytics;

  void logQuizStarted({
    required String categoryId,
    required String mode,
    required int quizSize,
  }) {
    _analytics.logEvent(
      'quiz_started',
      parameters: {
        'categoryId': categoryId,
        'mode': mode,
        'quizSize': quizSize,
      },
    );
  }

  void logQuizCompleted({
    required String categoryId,
    required int score,
    required int correctCount,
    required String mode,
  }) {
    _analytics.logEvent(
      'quiz_completed',
      parameters: {
        'categoryId': categoryId,
        'score': score,
        'correctCount': correctCount,
        'mode': mode,
      },
    );
  }

  void logCategoryExhausted({
    required String categoryId,
    required int poolSize,
    required int exhaustedCount,
    required String weekKey,
  }) {
    _analytics.logEvent(
      'category_exhausted',
      parameters: {
        'categoryId': categoryId,
        'poolSize': poolSize,
        'exhaustedCount': exhaustedCount,
        'weekKey': weekKey,
      },
    );
  }

  void logQuizSharedCreated({
    required String categoryId,
    required String quizId,
  }) {
    _analytics.logEvent(
      'quiz_shared_created',
      parameters: {
        'categoryId': categoryId,
        'quizId': quizId,
      },
    );
  }
}
