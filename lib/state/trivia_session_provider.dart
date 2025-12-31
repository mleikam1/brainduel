import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trivia_pack.dart';
import '../models/trivia_session.dart';
import '../services/storage_content_service.dart';
import '../services/content_cache_service.dart';
import '../services/trivia_session_builder.dart';
import '../services/analytics_service.dart';
import 'categories_provider.dart';

class TriviaGameState {
  final bool loading;
  final String? error;
  final TriviaSession? session;
  final int currentIndex;
  final int score;
  final String? selectedAnswerId;
  final bool isAnswered;
  final bool isTimedOut;

  const TriviaGameState({
    required this.loading,
    required this.error,
    required this.session,
    required this.currentIndex,
    required this.score,
    required this.selectedAnswerId,
    required this.isAnswered,
    required this.isTimedOut,
  });

  factory TriviaGameState.initial() => const TriviaGameState(
    loading: false,
    error: null,
    session: null,
    currentIndex: 0,
    score: 0,
    selectedAnswerId: null,
    isAnswered: false,
    isTimedOut: false,
  );

  TriviaGameState copyWith({
    bool? loading,
    String? error,
    TriviaSession? session,
    int? currentIndex,
    int? score,
    String? selectedAnswerId,
    bool? isAnswered,
    bool? isTimedOut,
  }) {
    return TriviaGameState(
      loading: loading ?? this.loading,
      error: error,
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      selectedAnswerId: selectedAnswerId ?? this.selectedAnswerId,
      isAnswered: isAnswered ?? this.isAnswered,
      isTimedOut: isTimedOut ?? this.isTimedOut,
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

  void selectAnswer(String answerId) {
    final session = state.session;
    if (session == null) return;
    if (state.isAnswered) return;

    final q = session.questions[state.currentIndex];
    final selected = q.answers.firstWhere((a) => a.id == answerId);
    final correct = selected.correct;

    state = state.copyWith(
      selectedAnswerId: answerId,
      isAnswered: true,
      isTimedOut: false,
      score: correct ? state.score + 1 : state.score,
    );

    ref.read(analyticsServiceProvider).logEvent(
      'answer_selected',
      parameters: {
        'questionId': q.id,
        'answerId': answerId,
        'correct': correct,
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
      selectedAnswerId: null,
      isAnswered: false,
      isTimedOut: false,
      error: null,
    );
  }

  void timeoutQuestion() {
    if (state.session == null) return;
    if (state.isAnswered) return;

    state = state.copyWith(
      selectedAnswerId: null,
      isAnswered: true,
      isTimedOut: true,
    );
  }

  void reset() {
    state = TriviaGameState.initial();
  }
}
