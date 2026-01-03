import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trivia_pack.dart';
import '../models/trivia_answer.dart';
import '../models/trivia_session.dart';
import '../services/storage_content_service.dart';
import '../services/content_cache_service.dart';
import '../services/trivia_session_builder.dart';
import '../services/analytics_service.dart';
import 'categories_provider.dart';

enum QuestionPhase {
  reading,
  answering,
  answered,
}

class TriviaGameState {
  final bool loading;
  final String? error;
  final TriviaSession? session;
  final int currentIndex;
  final int points;
  final int correctAnswers;
  final TriviaAnswer? selectedAnswer;
  final bool isAnswered;
  final bool isTimedOut;
  final QuestionPhase phase;
  final DateTime? answerPhaseStartedAt;

  const TriviaGameState({
    required this.loading,
    required this.error,
    required this.session,
    required this.currentIndex,
    required this.points,
    required this.correctAnswers,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isTimedOut,
    required this.phase,
    required this.answerPhaseStartedAt,
  });

  factory TriviaGameState.initial() => const TriviaGameState(
    loading: false,
    error: null,
    session: null,
    currentIndex: 0,
    points: 0,
    correctAnswers: 0,
    selectedAnswer: null,
    isAnswered: false,
    isTimedOut: false,
    phase: QuestionPhase.reading,
    answerPhaseStartedAt: null,
  );

  TriviaGameState copyWith({
    bool? loading,
    String? error,
    TriviaSession? session,
    int? currentIndex,
    int? points,
    int? correctAnswers,
    TriviaAnswer? selectedAnswer,
    bool? isAnswered,
    bool? isTimedOut,
    QuestionPhase? phase,
    DateTime? answerPhaseStartedAt,
  }) {
    return TriviaGameState(
      loading: loading ?? this.loading,
      error: error,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      points: points ?? this.points,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
      isTimedOut: isTimedOut ?? this.isTimedOut,
      phase: phase ?? this.phase,
      answerPhaseStartedAt: answerPhaseStartedAt ?? this.answerPhaseStartedAt,
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final triviaSessionBuilderProvider = Provider<TriviaSessionBuilder>((ref) {
  return TriviaSessionBuilder();
});

final triviaSessionProvider =
StateNotifierProvider<TriviaSessionNotifier, TriviaGameState>((ref) {
  return TriviaSessionNotifier(ref);
});

class TriviaSessionNotifier extends StateNotifier<TriviaGameState> {
  TriviaSessionNotifier(this.ref) : super(TriviaGameState.initial());

  final Ref ref;

  Future<void> startGame(String categoryId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final storage = ref.read(storageContentServiceProvider);
      final cache = ref.read(contentCacheServiceProvider);
      final builder = ref.read(triviaSessionBuilderProvider);
      final analytics = ref.read(analyticsServiceProvider);
      final packPath = ref.read(categoryPackPathProvider(categoryId));

      final packText = await cache.getCachedOrFetch(
        key: 'pack_$packPath',
        version: 1,
        fetcher: () => storage.downloadTextFile(packPath),
      );

      final decoded = json.decode(packText) as Map<String, dynamic>;
      final pack = TriviaPack.fromJson(decoded);

      if (pack.questions.length < kTriviaQuestionCount) {
        analytics.logEvent(
          'trivia_pack_insufficient_questions',
          parameters: {
            'categoryId': categoryId,
            'available': pack.questions.length,
            'required': kTriviaQuestionCount,
          },
        );
        state = state.copyWith(
          loading: false,
          session: null,
          error: 'More questions coming soon for this topic.',
        );
        return;
      }

      final session = builder.buildSession(pack: pack);

      analytics.logEvent('game_started', parameters: {'categoryId': categoryId});

      state = TriviaGameState.initial().copyWith(session: session, loading: false);
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

    final q = session.questions[state.currentIndex];
    final selected = q.displayAnswers.firstWhere((a) => a.id == answerId);
    final correct = selected.correct;
    final startedAt = state.answerPhaseStartedAt ?? DateTime.now();
    final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
    final withinTime = elapsedSeconds < 10;
    final earnedPoints = correct && withinTime ? (100 - (10 * elapsedSeconds)) : 0;
    final clampedPoints = earnedPoints.clamp(0, 100);

    state = state.copyWith(
      selectedAnswer: selected,
      isAnswered: true,
      isTimedOut: false,
      phase: QuestionPhase.answered,
      points: state.points + clampedPoints,
      correctAnswers: correct ? state.correctAnswers + 1 : state.correctAnswers,
    );

    ref.read(analyticsServiceProvider).logEvent(
      'answer_selected',
      parameters: {
        'questionId': q.id,
        'answerId': answerId,
        'correct': correct,
        'elapsedSeconds': elapsedSeconds,
        'points': clampedPoints,
      },
    );
  }

  bool get isLastQuestion {
    final session = state.session;
    if (session == null) return true;
    return state.currentIndex >= session.questions.length - 1;
  }

  void nextQuestion() {
    final session = state.session;
    if (session == null) return;

    if (isLastQuestion) return;

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedAnswer: null,
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
      selectedAnswer: null,
      isAnswered: true,
      isTimedOut: true,
      phase: QuestionPhase.answered,
    );
  }

  void reset() {
    state = TriviaGameState.initial();
  }
}
