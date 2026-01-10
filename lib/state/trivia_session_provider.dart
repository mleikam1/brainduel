import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_answer.dart';
import '../models/game_session.dart';
import '../services/analytics_service.dart';
import '../services/game_functions_service.dart';

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
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final triviaSessionProvider =
StateNotifierProvider<TriviaSessionNotifier, TriviaGameState>((ref) {
  return TriviaSessionNotifier(ref);
});

class TriviaSessionNotifier extends StateNotifier<TriviaGameState> {
  TriviaSessionNotifier(this.ref) : super(TriviaGameState.initial());

  final Ref ref;
  final Map<String, int> _selectedIndexByQuestionId = {};
  final Set<String> _completedGameIds = {};

  String _formatError(Object error) {
    if (error is GameFunctionsException && _isAlreadyCompletedError(error)) {
      return 'That game has already been completed.';
    }
    return error.toString();
  }

  bool _isAlreadyCompletedError(GameFunctionsException error) {
    final message = (error.message ?? '').toLowerCase();
    final details = error.details?.toString().toLowerCase() ?? '';
    if (error.code == 'already-completed') return true;
    if (error.code == 'failed-precondition' && (message.contains('completed') || details.contains('completed'))) {
      return true;
    }
    return message.contains('already completed') || details.contains('already completed');
  }

  Future<void> startGame(String categoryId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final gameFunctions = ref.read(gameFunctionsServiceProvider);
      final analytics = ref.read(analyticsServiceProvider);
      final session = await gameFunctions.createGame(categoryId);
      // Fairness requires server-generated question snapshots so clients cannot reshuffle or peek at answers.
      if (_completedGameIds.contains(session.gameId)) {
        state = state.copyWith(
          loading: false,
          session: null,
          error: 'That game has already been completed.',
        );
        return;
      }

      analytics.logEvent('game_started', parameters: {'topicId': categoryId});

      _selectedIndexByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _formatError(e));
    }
  }

  Future<void> loadGame(String gameId) async {
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
      analytics.logEvent('shared_game_loaded', parameters: {'gameId': gameId});

      _selectedIndexByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: _formatError(e));
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
    final answerId = q.choices[answerIndex];

    state = state.copyWith(
      selectedIndex: answerIndex,
      isAnswered: true,
      isTimedOut: false,
      hasAnsweredAny: true,
      phase: QuestionPhase.answered,
    );

    ref.read(analyticsServiceProvider).logEvent(
      'answer_selected',
      parameters: {
        'questionId': q.id,
        'answerId': answerId,
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

  Future<({int score, int maxScore, int? correct, int? total})?> completeGame() async {
    final session = state.session;
    if (session == null) return null;
    if (_completedGameIds.contains(session.gameId)) {
      state = state.copyWith(error: 'That game has already been completed.');
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
        );
      }).toList();
      final result = await ref.read(gameFunctionsServiceProvider).completeGame(
            session.gameId,
            answers,
          );
      _completedGameIds.add(session.gameId);
      state = state.copyWith(
        points: result.score,
        correctAnswers: result.correct ?? state.correctAnswers,
        isSubmitting: false,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _formatError(e));
      return null;
    }
  }

  void reset() {
    _selectedIndexByQuestionId.clear();
    state = TriviaGameState.initial();
  }
}
