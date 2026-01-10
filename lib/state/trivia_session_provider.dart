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
  final String? selectedChoiceId;
  final bool isAnswered;
  final bool isTimedOut;
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
    required this.selectedChoiceId,
    required this.isAnswered,
    required this.isTimedOut,
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
    selectedChoiceId: null,
    isAnswered: false,
    isTimedOut: false,
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
    String? selectedChoiceId,
    bool? isAnswered,
    bool? isTimedOut,
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
      selectedChoiceId: selectedChoiceId ?? this.selectedChoiceId,
      isAnswered: isAnswered ?? this.isAnswered,
      isTimedOut: isTimedOut ?? this.isTimedOut,
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
  final Map<String, GameAnswer> _answerByQuestionId = {};
  final Set<String> _completedGameIds = {};

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

      _answerByQuestionId.clear();
      state = TriviaGameState.initial().copyWith(
        session: session,
        loading: false,
        startedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void startAnswerPhase() {
    if (state.session == null) return;
    if (state.phase != QuestionPhase.reading) return;
    state = state.copyWith(
      phase: QuestionPhase.answering,
      answerPhaseStartedAt: DateTime.now(),
    );
  }

  void selectAnswer(String answerId) {
    final session = state.session;
    if (session == null) return;
    if (state.isAnswered) return;
    if (state.phase != QuestionPhase.answering) return;

    final q = session.questionsSnapshot[state.currentIndex];
    _answerByQuestionId[q.id] = GameAnswer(questionId: q.id, choice: answerId);

    state = state.copyWith(
      selectedChoiceId: answerId,
      isAnswered: true,
      isTimedOut: false,
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

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedChoiceId: null,
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

    state = state.copyWith(
      selectedChoiceId: null,
      isAnswered: true,
      isTimedOut: true,
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
      final answers = session.questionsSnapshot
          .map((question) => _answerByQuestionId[question.id])
          .whereType<GameAnswer>()
          .toList();
      final result = await ref.read(gameFunctionsServiceProvider).completeGame(
            session.gameId,
            answers,
          );
      _completedGameIds.add(session.gameId);
      state = state.copyWith(
        points: result.score,
        correctAnswers: result.correct ?? state.correctAnswers,
      );
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void reset() {
    _answerByQuestionId.clear();
    state = TriviaGameState.initial();
  }
}
