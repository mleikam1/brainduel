import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_answer.dart';
import '../models/game_question.dart';
import '../models/game_session.dart';
import '../models/quiz_result.dart';
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
  final bool hasSubmitted;
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
    required this.hasSubmitted,
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
    hasSubmitted: false,
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
    bool? hasSubmitted,
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
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
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
  // Store immutable answer snapshots per question index so answers don't get overwritten.
  final Map<int, QuizResultAnswer> _answersByIndex = {};
  final Set<String> _completedGameIds = {};
  final Set<String> _submittedGameResultIds = {};
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

  bool _shouldLogBackendFailure(GameFunctionsException error) {
    // Avoid logging expected backend responses (failed-precondition for completed games or
    // no-questions responses) to keep analytics focused on unexpected backend failures.
    if (error.code == 'failed-precondition') return false;
    if (_isAlreadyCompletedError(error)) return false;
    if (_isNoQuestionsError(error)) return false;
    return true;
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
      return;
    }
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
      return;
    }
    _isStarting = true;
    state = state.copyWith(loading: true, error: null);
    try {
      final categories = await ref.read(categoriesProvider.future);
      final categoryExists = categories.any((category) => category.id == trimmedCategoryId);
      if (!categoryExists) {
        state = _markGameStartFailure('That category is not available right now.');
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
        if (_shouldLogBackendFailure(e)) {
          _logGameFailed('start', code: e.code);
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

      _answersByIndex.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController startGame error: $e');
      debugPrintStack(stackTrace: st);
      state = _markGameStartFailure(_formatError(e));
    } finally {
      _isStarting = false;
    }
  }

  Future<void> loadGame(String gameId) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
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

      _answersByIndex.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController loadGame error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
        } else if (_shouldLogBackendFailure(e)) {
          _logGameFailed('load', code: e.code);
          state = _markGameStartFailure(_messageForGameError(e));
        } else {
          state = _markGameStartFailure(_messageForGameError(e));
        }
      } else {
        state = _markGameStartFailure(_formatError(e));
      }
    }
  }

  Future<void> loadSharedQuiz(String quizId) async {
    final trimmedQuizId = quizId.trim();
    if (trimmedQuizId.isEmpty) {
      state = state.copyWith(error: 'This shared quiz link is missing an ID.');
      return;
    }
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
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

      _answersByIndex.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController loadSharedQuiz error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
        } else if (_shouldLogBackendFailure(e)) {
          _logGameFailed('load_shared', code: e.code);
          state = _markGameStartFailure(_messageForGameError(e));
        } else {
          state = _markGameStartFailure(_messageForGameError(e));
        }
      } else {
        state = _markGameStartFailure(_formatError(e));
      }
    }
  }

  Future<void> loadTriviaPack(String triviaPackId) async {
    final trimmedPackId = triviaPackId.trim();
    if (trimmedPackId.isEmpty) {
      state = state.copyWith(error: 'This shared pack link is missing an ID.');
      return;
    }
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.isEmpty) {
      state = _markGameStartFailure('Please sign in to continue.');
      return;
    }
    final userReady = ref.read(userBootstrapReadyProvider);
    if (!userReady) {
      state = _markGameStartFailure(
        'Your account is still getting set up. Please try again shortly.',
      );
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

      _answersByIndex.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('QuizController loadTriviaPack error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state.copyWith(loading: false),
            message: _messageForGameError(e),
          );
        } else if (_shouldLogBackendFailure(e)) {
          _logGameFailed('load_pack', code: e.code);
          state = _markGameStartFailure(_messageForGameError(e));
        } else {
          state = _markGameStartFailure(_messageForGameError(e));
        }
      } else {
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
    if (_answersByIndex.containsKey(state.currentIndex)) return;
    if (answerIndex < 0 || answerIndex >= q.choices.length) return;
    final boundedAnswerIndex = answerIndex.clamp(0, q.choices.length - 1);
    final selectedAnswerId = q.choiceIds.isNotEmpty
        ? q.choiceIds[boundedAnswerIndex]
        : GameQuestion.buildChoiceId(q.id, q.choices[boundedAnswerIndex]);
    _answersByIndex[state.currentIndex] = QuizResultAnswer(
      questionId: q.id,
      selectedAnswerId: selectedAnswerId,
      correctAnswerId: q.correctAnswerId,
    );
    state = state.copyWith(
      selectedIndex: boundedAnswerIndex,
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
    if (_answersByIndex.containsKey(state.currentIndex)) return;
    final fallbackAnswerId =
        _answersByIndex[state.currentIndex]?.selectedAnswerId ??
            (q.choiceIds.isNotEmpty ? q.choiceIds.first : '');
    final boundedIndex = q.choiceIds.indexOf(fallbackAnswerId).clamp(
          0,
          q.choices.length - 1,
        );
    _answersByIndex[state.currentIndex] = QuizResultAnswer(
      questionId: q.id,
      selectedAnswerId: fallbackAnswerId,
      correctAnswerId: q.correctAnswerId,
    );

    state = state.copyWith(
      selectedIndex: boundedIndex,
      isAnswered: true,
      isTimedOut: true,
      hasAnsweredAny: true,
      phase: QuestionPhase.answered,
    );
  }

  List<QuizResultAnswer> _buildQuizAnswers(GameSession session) {
    return session.questionsSnapshot.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final storedAnswer = _answersByIndex[index];
      final selectedAnswerId = storedAnswer?.selectedAnswerId ??
          (question.choiceIds.isNotEmpty ? question.choiceIds.first : '');
      return QuizResultAnswer(
        questionId: question.id,
        selectedAnswerId: selectedAnswerId,
        correctAnswerId: question.correctAnswerId,
      );
    }).toList();
  }

  List<GameAnswer> _buildGameAnswers(GameSession session, QuizResult result) {
    final questionById = {
      for (final question in session.questionsSnapshot) question.id: question,
    };
    return result.answers.map((answer) {
      final question = questionById[answer.questionId];
      if (question == null || question.choices.isEmpty) {
        return GameAnswer(
          questionId: answer.questionId,
          choice: '',
          selectedIndex: 0,
        );
      }
      final selectedIndex = question.choiceIds.indexOf(answer.selectedAnswerId);
      final boundedIndex = selectedIndex == -1
          ? 0
          : selectedIndex.clamp(0, question.choices.length - 1);
      return GameAnswer(
        questionId: answer.questionId,
        choice: question.choices[boundedIndex],
        selectedIndex: boundedIndex,
      );
    }).toList();
  }

  Future<QuizResult?> completeGame() async {
    final session = state.session;
    if (session == null) return null;
    if (_completedGameIds.contains(session.gameId)) {
      state = _markAlreadyCompleted(state);
      return null;
    }
    try {
      state = state.copyWith(
        isSubmitting: true,
        hasSubmitted: true,
        error: null,
      );
      final answers = _buildQuizAnswers(session);
      // Compute correctness once at completion using stable answer IDs.
      var correctCount = 0;
      for (final answer in answers) {
        final isCorrect = answer.selectedAnswerId == answer.correctAnswerId;
        if (isCorrect) {
          correctCount += 1;
        }
        debugPrint(
          'QuizController completeGame answer: '
          'questionId=${answer.questionId} '
          'selectedAnswerId=${answer.selectedAnswerId} '
          'correctAnswerId=${answer.correctAnswerId} '
          'isCorrect=$isCorrect',
        );
      }
      final score = correctCount * 100;
      final result = QuizResult(
        totalQuestions: answers.length,
        correctCount: correctCount,
        score: score,
        answers: answers,
      );
      debugPrint(
        'QuizController completeGame summary: total=${result.totalQuestions} '
        'correct=${result.correctCount} '
        'details=${result.answers.map((answer) => '${answer.questionId}:${answer.selectedAnswerId == answer.correctAnswerId}').join(', ')}',
      );
      _completedGameIds.add(session.gameId);
      state = state.copyWith(
        points: result.score,
        correctAnswers: result.correctCount,
        isSubmitting: false,
        isLocked: true,
      );
      _logQuizCompleted(
        session: session,
        score: result.score,
        correctCount: result.correctCount,
        mode: _activeMode ?? 'solo',
      );
      ref.read(analyticsServiceProvider).logEvent(
        'trivia_game_completed',
        parameters: {
          'gameId': session.gameId,
          'score': result.score,
          'maxScore': result.totalQuestions * 100,
          'total': result.totalQuestions,
        },
      );
      return result;
    } catch (e, st) {
      debugPrint('QuizController completeGame error: $e');
      debugPrintStack(stackTrace: st);
      if (e is GameFunctionsException) {
        if (e.code == 'failed-precondition') {
          // Backend already finalized the game; treat as completed locally to stop retries,
          // avoid analytics noise, and block any score submissions for a finalized game.
          _completedGameIds.add(session.gameId);
          state = state.copyWith(
            isSubmitting: false,
            isLocked: true,
            showAlreadyCompletedModal: true,
            error: _messageForGameError(e),
          );
          return null;
        }
        if (_isAlreadyCompletedError(e)) {
          state = _markAlreadyCompleted(
            state,
            message: _messageForGameError(e),
          );
        } else {
          if (_shouldLogBackendFailure(e)) {
            _logGameFailed('complete', code: e.code);
          }
          state = state.copyWith(
            isSubmitting: false,
            error: _messageForGameError(e),
          );
        }
      } else {
        state = state.copyWith(isSubmitting: false, error: _formatError(e));
      }
      return null;
    }
  }

  Future<QuizResult?> completeTriviaPack() async {
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
    return completeGame();
  }

  Future<bool> submitGameResult(QuizResult result) async {
    final session = state.session;
    if (session == null) return false;
    if (_submittedGameResultIds.contains(session.gameId)) return true;
    final answers = _buildGameAnswers(session, result);
    try {
      try {
        await ref.read(gameFunctionsServiceProvider).completeGame(session.gameId, answers);
      } on GameFunctionsException catch (e) {
        if (!_isAlreadyCompletedError(e)) {
          rethrow;
        }
      }
      final triviaPackId = session.triviaPackId;
      if (triviaPackId != null && triviaPackId.isNotEmpty) {
        final durationMs = state.startedAt == null
            ? null
            : DateTime.now().difference(state.startedAt!).inMilliseconds;
        try {
          await ref.read(gameFunctionsServiceProvider).submitSoloScore(
                gameId: session.gameId,
                categoryId: session.topicId,
                triviaPackId: triviaPackId,
                score: result.score,
                correctCount: result.correctCount,
                totalQuestions: result.totalQuestions,
                durationMs: durationMs,
                mode: 'solo',
              );
        } on GameFunctionsException catch (e, st) {
          debugPrint('QuizController submitSoloScore error: $e');
          debugPrintStack(stackTrace: st);
          return false;
        }
      }
      _submittedGameResultIds.add(session.gameId);
      return true;
    } catch (e, st) {
      debugPrint('QuizController submitGameResult error: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  void dismissAlreadyCompletedModal() {
    if (!state.showAlreadyCompletedModal) return;
    state = state.copyWith(showAlreadyCompletedModal: false);
  }

  void reset() {
    _answersByIndex.clear();
    _loggedEventKeys.clear();
    _submittedGameResultIds.clear();
    _activeMode = null;
    state = TriviaGameState.initial();
  }
}
