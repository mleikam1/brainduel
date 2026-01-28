import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_answer.dart';
import '../models/game_session.dart';
import '../models/solo_pack_leaderboard.dart';
import '../services/analytics_service.dart';
import '../services/game_functions_service.dart';
import '../services/quiz_analytics.dart';
import '../services/quiz_repository.dart';
import 'auth_provider.dart';
import 'categories_provider.dart';

enum QuestionPhase {
  reading,
  answering,
  answered,
}

class TriviaGameState {
  final bool loading;
  final String? error;
  final GameSession? session;
  final int currentIndex;
  final int points;
  final int correctAnswers;
  final int? selectedIndex;
  final bool isAnswered;
  final bool isTimedOut;
  final bool isSubmitting;
  final bool hasAnsweredAny;
  final QuestionPhase phase;
  final DateTime? answerPhaseStartedAt;
  final DateTime? startedAt;
  final bool isLocked;
  final bool showAlreadyCompletedModal;
  final SoloPackLeaderboard? packLeaderboard;

  const TriviaGameState({
    required this.loading,
    required this.error,
    required this.session,
    required this.currentIndex,
    required this.points,
    required this.correctAnswers,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isTimedOut,
    required this.isSubmitting,
    required this.hasAnsweredAny,
    required this.phase,
    required this.answerPhaseStartedAt,
    required this.startedAt,
    required this.isLocked,
    required this.showAlreadyCompletedModal,
    required this.packLeaderboard,
  });

  factory TriviaGameState.initial() => const TriviaGameState(
    loading: false,
    error: null,
    session: null,
    currentIndex: 0,
    points: 0,
    correctAnswers: 0,
    selectedIndex: null,
    isAnswered: false,
    isTimedOut: false,
    isSubmitting: false,
    hasAnsweredAny: false,
    phase: QuestionPhase.reading,
    answerPhaseStartedAt: null,
    startedAt: null,
    isLocked: false,
    showAlreadyCompletedModal: false,
    packLeaderboard: null,
  );

  TriviaGameState copyWith({
    bool? loading,
    String? error,
    GameSession? session,
    int? currentIndex,
    int? points,
    int? correctAnswers,
    int? selectedIndex,
    bool? isAnswered,
    bool? isTimedOut,
    bool? isSubmitting,
    bool? hasAnsweredAny,
    QuestionPhase? phase,
    DateTime? answerPhaseStartedAt,
    DateTime? startedAt,
    bool? isLocked,
    bool? showAlreadyCompletedModal,
    SoloPackLeaderboard? packLeaderboard,
  }) {
    return TriviaGameState(
      loading: loading ?? this.loading,
      error: error,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      points: points ?? this.points,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isAnswered: isAnswered ?? this.isAnswered,
      isTimedOut: isTimedOut ?? this.isTimedOut,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasAnsweredAny: hasAnsweredAny ?? this.hasAnsweredAny,
      phase: phase ?? this.phase,
      answerPhaseStartedAt: answerPhaseStartedAt ?? this.answerPhaseStartedAt,
      startedAt: startedAt ?? this.startedAt,
      isLocked: isLocked ?? this.isLocked,
      showAlreadyCompletedModal: showAlreadyCompletedModal ?? this.showAlreadyCompletedModal,
      packLeaderboard: packLeaderboard ?? this.packLeaderboard,
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final quizControllerProvider =
    StateNotifierProvider<QuizController, TriviaGameState>((ref) {
  return QuizController(ref);
});

class QuizController extends StateNotifier<TriviaGameState> {
  QuizController(this.ref)
      : _quizAnalytics = QuizAnalyticsHelper(ref.read(analyticsServiceProvider)),
        super(TriviaGameState.initial());

  final Ref ref;
  final Map<String, int> _selectedIndexByQuestionId = {};
  final Set<String> _completedGameIds = {};
  final Set<String> _loggedEventKeys = {};
  final QuizAnalyticsHelper _quizAnalytics;
  bool _isStarting = false;
  String? _activeMode;

  String _formatError(Object error) {
    if (error is QuizRepositoryException) {
      return _messageForQuizError(error);
    }
    if (error is GameFunctionsException) {
      return _messageForGameError(error);
    }
    return error.toString();
  }

  String _messageForQuizError(QuizRepositoryException error) {
    if (_isAlreadyCompletedError(error)) {
      return 'That game has already been completed.';
    }
    switch (error.code) {
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'failed-precondition':
        final details = _formatErrorDetails(error.message, error.details);
        if (details.contains('no_questions_exist_for_topic')) {
          return 'No questions are available for this category yet. Please try another.';
        }
        return 'Unable to start game. Please try again.';
      case 'not-found':
        return 'That game could not be found.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  String _messageForGameError(GameFunctionsException error) {
    if (_isAlreadyCompletedError(error)) {
      return 'That game has already been completed.';
    }
    switch (error.code) {
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'failed-precondition':
        final details = _formatErrorDetails(error.message, error.details);
        if (details.contains('no_questions_exist_for_topic')) {
          return 'No questions are available for this category yet. Please try another.';
        }
        return 'Unable to start game. Please try again.';
      case 'not-found':
        return 'That game could not be found.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  String _formatErrorDetails(String? messageValue, Object? detailsValue) {
    final message = (messageValue ?? '').toLowerCase();
    final details = detailsValue?.toString().toLowerCase() ?? '';
    return '$message $details'.trim();
  }

  bool _isAlreadyCompletedError(Object error) {
    if (error is QuizRepositoryException) {
      return _matchesAlreadyCompleted(error.code, error.message, error.details);
    }
    if (error is GameFunctionsException) {
      return _matchesAlreadyCompleted(error.code, error.message, error.details);
    }
    return false;
  }

  bool _matchesAlreadyCompleted(String code, String? messageValue, Object? detailsValue) {
    final message = (messageValue ?? '').toLowerCase();
    final details = detailsValue?.toString().toLowerCase() ?? '';
    if (code == 'already-completed') return true;
    if (code == 'failed-precondition' &&
        (message.contains('completed') || details.contains('completed'))) {
      return true;
    }
    return message.contains('already completed') || details.contains('already completed');
  }

  TriviaGameState _markAlreadyCompleted(TriviaGameState current, {String? message}) {
    final session = current.session;
    if (session != null) {
      _completedGameIds.add(session.gameId);
    }
    return current.copyWith(
      isSubmitting: false,
      isLocked: true,
      showAlreadyCompletedModal: true,
      error: message ?? 'That game has already been completed.',
    );
  }

  TriviaGameState _markGameStartFailure(String message) {
    return TriviaGameState.initial().copyWith(
      loading: false,
      error: message,
    );
  }

  void _logGameFailed(String stage, {String? code}) {
    ref.read(analyticsServiceProvider).logEvent(
      'trivia_game_failed',
      parameters: {
        'stage': stage,
        if (code != null) 'code': code,
      },
    );
  }

  void _logBackendStartEvent({
    required String event,
    required String topicId,
    String? code,
    String? message,
    Object? details,
  }) {
    ref.read(analyticsServiceProvider).logEvent(
      event,
      parameters: {
        'topicId': topicId,
        if (code != null) 'code': code,
        if (message != null) 'message': message,
        if (details != null) 'details': details.toString(),
      },
    );
  }

  void _logGameBlockedNoQuestions({
    required String topicId,
    Object? details,
  }) {
    ref.read(analyticsServiceProvider).logEvent(
      'trivia_game_blocked',
      parameters: {
        'reason': 'no_questions',
        'topic': topicId,
        if (details != null) 'details': details,
      },
    );
  }

  bool _isNoQuestionsError(Object error) {
    if (error is QuizRepositoryException) {
      return _formatErrorDetails(error.message, error.details)
          .contains('no_questions_exist_for_topic');
    }
    if (error is GameFunctionsException) {
      return _formatErrorDetails(error.message, error.details)
          .contains('no_questions_exist_for_topic');
    }
    return false;
  }

  void _logOnce(String key, VoidCallback callback) {
    if (!_loggedEventKeys.add(key)) return;
    callback();
  }

  void _logQuizStarted(GameSession session, {required String mode}) {
    _logOnce('quiz_started:${session.gameId}', () {
      _quizAnalytics.logQuizStarted(
        categoryId: session.topicId,
        mode: mode,
        quizSize: session.questionsSnapshot.length,
      );
    });
  }

  void _logQuizCompleted({
    required GameSession session,
    required int score,
    required int correctCount,
    required String mode,
  }) {
    _logOnce('quiz_completed:${session.gameId}', () {
      _quizAnalytics.logQuizCompleted(
        categoryId: session.topicId,
        score: score,
        correctCount: correctCount,
        mode: mode,
      );
    });
  }

  void _logQuizSharedCreated({
    required String categoryId,
    required String quizId,
  }) {
    _logOnce('quiz_shared_created:$quizId', () {
      _quizAnalytics.logQuizSharedCreated(
        categoryId: categoryId,
        quizId: quizId,
      );
    });
  }

  Future<void> startGame(String categoryId) async {
    if (state.loading || _isStarting) return;
    final trimmedCategoryId = categoryId.trim();
    if (trimmedCategoryId.isEmpty) {
      state = _markGameStartFailure('Please choose a category to continue.');
      _logGameFailed('start', code: 'missing-category');
      return;
    }
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      _logGameFailed('start', code: 'unauthenticated');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
      _logGameFailed('start', code: 'user-not-ready');
      return;
    }
    _isStarting = true;
    state = state.copyWith(loading: true, error: null);
    try {
      final categories = await ref.read(categoriesProvider.future);
      final categoryExists = categories.any((category) => category.id == trimmedCategoryId);
      if (!categoryExists) {
        state = _markGameStartFailure('That category is not available right now.');
        _logGameFailed('start', code: 'category-unavailable');
        return;
      }
      final analytics = ref.read(analyticsServiceProvider);
      GameSession session;
      try {
        session = await ref.read(gameFunctionsServiceProvider).createGame(
              topicId: trimmedCategoryId,
              mode: 'solo',
            );
      } on GameFunctionsException catch (e, st) {
        debugPrint(
          'QuizController startGame createGame error: code=${e.code} message=${e.message} details=${e.details}',
        );
        debugPrintStack(stackTrace: st);
        _logGameFailed('start', code: e.code);
        if (_isNoQuestionsError(e)) {
          _logBackendStartEvent(
            event: 'backend_no_questions',
            topicId: trimmedCategoryId,
            code: e.code,
            message: e.message,
            details: e.details,
          );
          _logGameBlockedNoQuestions(
            topicId: trimmedCategoryId,
            details: e.details,
          );
          state = _markGameStartFailure(_messageForGameError(e));
          return;
        }
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
          return;
        }
        _logBackendStartEvent(
          event: 'backend_unrecoverable_error',
          topicId: trimmedCategoryId,
          code: e.code,
          message: e.message,
          details: e.details,
        );
        state = _markGameStartFailure(_messageForGameError(e));
        return;
      }
      // Fairness requires server-generated question snapshots so clients cannot reshuffle or peek at answers.
      if (_completedGameIds.contains(session.gameId)) {
        state = state.copyWith(
          loading: false,
          session: null,
          error: 'That game has already been completed.',
        );
        return;
      }

      analytics.logEvent('trivia_game_started', parameters: {
        'topicId': trimmedCategoryId,
        'mode': 'solo',
        'gameId': session.gameId,
        'source': 'category',
      });

      _activeMode = 'solo';
      _logQuizStarted(session, mode: 'solo');

      _selectedIndexByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController startGame error: $e');
      debugPrintStack(stackTrace: st);
      _logGameFailed('start');
      state = _markGameStartFailure(_formatError(e));
    } finally {
      _isStarting = false;
    }
  }

  Future<void> loadGame(String gameId) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      _logGameFailed('load', code: 'unauthenticated');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
      _logGameFailed('load', code: 'user-not-ready');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final gameFunctions = ref.read(gameFunctionsServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);
      final session = await gameFunctions.loadGame(gameId);
      if (_completedGameIds.contains(session.gameId)) {
        state = state.copyWith(
          loading: false,
          session: null,
          error: 'That game has already been completed.',
        );
        return;
      }
      analytics.logEvent('trivia_game_started', parameters: {
        'gameId': gameId,
        'source': 'shared',
      });

      _activeMode = 'shared';
      _logQuizStarted(session, mode: 'shared');

      _selectedIndexByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController loadGame error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        _logGameFailed('load', code: e.code);
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
        } else {
          state = _markGameStartFailure(_messageForGameError(e));
        }
      } else {
        _logGameFailed('load');
        state = _markGameStartFailure(_formatError(e));
      }
    }
  }

  Future<void> loadSharedQuiz(String quizId) async {
    final trimmedQuizId = quizId.trim();
    if (trimmedQuizId.isEmpty) {
      state = state.copyWith(error: 'This shared quiz link is missing an ID.');
      _logGameFailed('load_shared', code: 'missing-quiz-id');
      return;
    }
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      _logGameFailed('load_shared', code: 'unauthenticated');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
      _logGameFailed('load_shared', code: 'user-not-ready');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final gameFunctions = ref.read(gameFunctionsServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);
      final session = await gameFunctions.getSharedQuiz(trimmedQuizId);
      if (_completedGameIds.contains(session.gameId)) {
        state = state.copyWith(
          loading: false,
          session: null,
          error: 'That quiz has already been completed.',
        );
        return;
      }
      analytics.logEvent('trivia_game_started', parameters: {
        'gameId': session.gameId,
        'quizId': trimmedQuizId,
        'source': 'shared_quiz',
      });

      _activeMode = 'shared';
      _logQuizStarted(session, mode: 'shared');

      _selectedIndexByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController loadSharedQuiz error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        _logGameFailed('load_shared', code: e.code);
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
        } else {
          state = _markGameStartFailure(_messageForGameError(e));
        }
      } else {
        _logGameFailed('load_shared');
        state = _markGameStartFailure(_formatError(e));
      }
    }
  }

  Future<void> loadTriviaPack(String triviaPackId) async {
    final trimmedPackId = triviaPackId.trim();
    if (trimmedPackId.isEmpty) {
      state = state.copyWith(error: 'This shared pack link is missing an ID.');
      _logGameFailed('load_pack', code: 'missing-pack-id');
      return;
    }
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      _logGameFailed('load_pack', code: 'unauthenticated');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
      _logGameFailed('load_pack', code: 'user-not-ready');
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final gameFunctions = ref.read(gameFunctionsServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);
      final session = await gameFunctions.getTriviaPack(trimmedPackId);
      if (_completedGameIds.contains(session.gameId)) {
        state = state.copyWith(
          loading: false,
          session: null,
          error: 'That trivia pack has already been completed.',
        );
        return;
      }
      analytics.logEvent('trivia_game_started', parameters: {
        'gameId': session.gameId,
        'triviaPackId': trimmedPackId,
        'source': 'shared_pack',
      });

      _activeMode = 'pack';
      _logQuizStarted(session, mode: 'pack');

      _selectedIndexByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController loadTriviaPack error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        _logGameFailed('load_pack', code: e.code);
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
        } else {
          state = _markGameStartFailure(_messageForGameError(e));
        }
      } else {
        _logGameFailed('load_pack');
        state = _markGameStartFailure(_formatError(e));
      }
    }
  }

  Future<String?> createSharedQuiz() async {
    final session = state.session;
    if (session == null || state.isSubmitting) return null;
    final questionIds = session.questionsSnapshot.map((question) => question.id).toList();
    try {
      final result = await ref.read(gameFunctionsServiceProvider).createSharedQuiz(
            categoryId: session.topicId,
            questionIds: questionIds,
            quizSize: questionIds.length,
          );
      _logQuizSharedCreated(
        categoryId: result.categoryId,
        quizId: result.quizId,
      );
      return result.quizId;
    } catch (e, st) {
      debugPrint('QuizController createSharedQuiz error: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  void startAnswerPhase() {
    if (state.session == null) return;
    if (state.phase != QuestionPhase.reading) return;
    if (state.isSubmitting) return;
    state = state.copyWith(
      phase: QuestionPhase.answering,
      answerPhaseStartedAt: DateTime.now(),
    );
  }

  void selectAnswer(int answerIndex) {
    final session = state.session;
    if (session == null) return;
    if (state.isAnswered) return;
    if (state.phase != QuestionPhase.answering) return;
    if (state.isSubmitting) return;

    final q = session.questionsSnapshot[state.currentIndex];
    if (_selectedIndexByQuestionId.containsKey(q.id)) return;
    if (answerIndex < 0 || answerIndex >= q.choices.length) return;
    _selectedIndexByQuestionId[q.id] = answerIndex;
    state = state.copyWith(
      selectedIndex: answerIndex,
      isAnswered: true,
      isTimedOut: false,
      hasAnsweredAny: true,
      phase: QuestionPhase.answered,
    );

    ref.read(analyticsServiceProvider).logEvent(
      'trivia_answer_selected',
      parameters: {
        'questionId': q.id,
      },
    );
  }

  bool get isLastQuestion {
    final session = state.session;
    if (session == null) return true;
    return state.currentIndex >= session.questionsSnapshot.length - 1;
  }

  void nextQuestion() {
    final session = state.session;
    if (session == null) return;

    if (isLastQuestion) return;
    if (state.isSubmitting) return;

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedIndex: null,
      isAnswered: false,
      isTimedOut: false,
      error: null,
      phase: QuestionPhase.reading,
      answerPhaseStartedAt: null,
    );
  }

  void timeoutQuestion() {
    if (state.session == null) return;
    if (state.isAnswered) return;
    if (state.isSubmitting) return;

    final q = state.session!.questionsSnapshot[state.currentIndex];
    final fallbackIndex = _selectedIndexByQuestionId[q.id] ?? 0;
    final boundedIndex = fallbackIndex.clamp(0, q.choices.length - 1);
    _selectedIndexByQuestionId[q.id] = boundedIndex;

    state = state.copyWith(
      selectedIndex: boundedIndex,
      isAnswered: true,
      isTimedOut: true,
      hasAnsweredAny: true,
      phase: QuestionPhase.answered,
    );
  }

  Future<({int score, int maxScore, int? correct, int? total, SoloPackLeaderboard? leaderboard})?>
      completeGame() async {
    final session = state.session;
    if (session == null) return null;
    if (_completedGameIds.contains(session.gameId)) {
      state = _markAlreadyCompleted(state);
      return null;
    }
    try {
      state = state.copyWith(isSubmitting: true, error: null);
      final answers = session.questionsSnapshot.map((question) {
        final index = _selectedIndexByQuestionId[question.id] ?? 0;
        final boundedIndex = index.clamp(0, question.choices.length - 1);
        return GameAnswer(
          questionId: question.id,
          choice: question.choices[boundedIndex],
          selectedIndex: boundedIndex,
        );
      }).toList();
      final result = await ref.read(gameFunctionsServiceProvider).completeGame(
            session.gameId,
            answers,
          );
      _completedGameIds.add(session.gameId);
      SoloPackLeaderboard? leaderboard;
      final triviaPackId = session.triviaPackId;
      if (triviaPackId != null && triviaPackId.isNotEmpty) {
        final durationSeconds = state.startedAt == null
            ? null
            : DateTime.now().difference(state.startedAt!).inSeconds;
        try {
          final leaderboardResult =
              await ref.read(gameFunctionsServiceProvider).submitSoloScore(
                    triviaPackId: triviaPackId,
                    score: result.score,
                    correct: result.correct,
                    total: result.total,
                    durationSeconds: durationSeconds,
                  );
          leaderboard = leaderboardResult.leaderboard;
        } on GameFunctionsException catch (e, st) {
          debugPrint(
            'QuizController completeGame submitSoloScore error: code=${e.code} message=${e.message} details=${e.details}',
          );
          debugPrintStack(stackTrace: st);
          if (e.code != 'failed-precondition') {
            rethrow;
          }
        }
      }
      state = state.copyWith(
        points: result.score,
        correctAnswers: result.correct ?? state.correctAnswers,
        isSubmitting: false,
        isLocked: true,
        packLeaderboard: leaderboard,
      );
      _logQuizCompleted(
        session: session,
        score: result.score,
        correctCount: result.correct ?? state.correctAnswers,
        mode: _activeMode ?? 'solo',
      );
      ref.read(analyticsServiceProvider).logEvent(
        'trivia_game_completed',
        parameters: {
          'gameId': session.gameId,
          'score': result.score,
          'maxScore': result.maxScore,
          'total': result.total ?? session.questionsSnapshot.length,
        },
      );
      return (
        score: result.score,
        maxScore: result.maxScore,
        correct: result.correct,
        total: result.total,
        leaderboard: leaderboard,
      );
    } catch (e, st) {
      debugPrint('QuizController completeGame error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        _logGameFailed('complete', code: e.code);
        if (e.code == 'failed-precondition') {
          state = _markAlreadyCompleted(
            state,
            message: _messageForGameError(e),
          );
          return null;
        }
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state,
            message: _messageForGameError(e),
          );
        } else {
          state = state.copyWith(
            isSubmitting: false,
            error: _messageForGameError(e),
          );
        }
      } else {
        _logGameFailed('complete');
        state = state.copyWith(isSubmitting: false, error: _formatError(e));
      }
      return null;
    }
  }

  Future<({int score, int maxScore, int? correct, int? total, SoloPackLeaderboard leaderboard})?>
      completeTriviaPack() async {
    final session = state.session;
    if (session == null) return null;
    if (_completedGameIds.contains(session.gameId)) {
      state = _markAlreadyCompleted(state);
      return null;
    }
    final triviaPackId = session.triviaPackId;
    if (triviaPackId == null || triviaPackId.isEmpty) {
      state = state.copyWith(error: 'Unable to submit pack score.');
      return null;
    }
    try {
      state = state.copyWith(isSubmitting: true, error: null);
      final answers = session.questionsSnapshot.map((question) {
        final index = _selectedIndexByQuestionId[question.id] ?? 0;
        final boundedIndex = index.clamp(0, question.choices.length - 1);
        return GameAnswer(
          questionId: question.id,
          choice: question.choices[boundedIndex],
          selectedIndex: boundedIndex,
        );
      }).toList();
      final durationSeconds = state.startedAt == null
          ? null
          : DateTime.now().difference(state.startedAt!).inSeconds;
      final result = await ref.read(gameFunctionsServiceProvider).submitSoloScore(
            triviaPackId: triviaPackId,
            score: 0,
            correct: state.correctAnswers,
            total: session.questionsSnapshot.length,
            durationSeconds: durationSeconds,
            answers: answers,
          );
      state = state.copyWith(
        points: result.score,
        correctAnswers: result.correct ?? state.correctAnswers,
        isSubmitting: false,
        isLocked: true,
        packLeaderboard: result.leaderboard,
      );
      _logQuizCompleted(
        session: session,
        score: result.score,
        correctCount: result.correct ?? state.correctAnswers,
        mode: _activeMode ?? 'pack',
      );
      return (
        score: result.score,
        maxScore: result.maxScore,
        correct: result.correct,
        total: result.total,
        leaderboard: result.leaderboard,
      );
    } catch (e, st) {
      debugPrint('QuizController completeTriviaPack error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        _logGameFailed('complete_pack', code: e.code);
        if (e.code == 'failed-precondition') {
          state = _markAlreadyCompleted(
            state,
            message: _messageForGameError(e),
          );
          return null;
        }
        state = state.copyWith(
          isSubmitting: false,
          error: _messageForGameError(e),
        );
      } else {
        _logGameFailed('complete_pack');
        state = state.copyWith(isSubmitting: false, error: _formatError(e));
      }
      return null;
    }
  }

  void dismissAlreadyCompletedModal() {
    if (!state.showAlreadyCompletedModal) return;
    state = state.copyWith(showAlreadyCompletedModal: false);
  }

  void reset() {
    _selectedIndexByQuestionId.clear();
    _loggedEventKeys.clear();
    _activeMode = null;
    state = TriviaGameState.initial();
  }
}
