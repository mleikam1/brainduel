import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../services/challenge_service.dart';
import 'categories_provider.dart';

final challengeServiceProvider = Provider<ChallengeService>((ref) {
  return ChallengeService(
    storage: ref.read(storageContentServiceProvider),
    cache: ref.read(contentCacheServiceProvider),
  );
});

final challengeMetadataProvider = FutureProvider.family<ChallengeMetadata, String>((ref, id) {
  return ref.read(challengeServiceProvider).fetchMetadata(id);
});

class ChallengeAttemptState {
  final bool loading;
  final String? error;
  final ChallengeAttempt? attempt;
  final int currentIndex;
  final Map<String, String> selectedAnswers;

  const ChallengeAttemptState({
    required this.loading,
    required this.error,
    required this.attempt,
    required this.currentIndex,
    required this.selectedAnswers,
  });

  factory ChallengeAttemptState.initial() => const ChallengeAttemptState(
    loading: false,
    error: null,
    attempt: null,
    currentIndex: 0,
    selectedAnswers: {},
  );

  ChallengeAttemptState copyWith({
    bool? loading,
    String? error,
    ChallengeAttempt? attempt,
    int? currentIndex,
    Map<String, String>? selectedAnswers,
  }) {
    return ChallengeAttemptState(
      loading: loading ?? this.loading,
      error: error,
      attempt: attempt ?? this.attempt,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    );
  }
}

final challengeAttemptProvider =
StateNotifierProvider<ChallengeAttemptNotifier, ChallengeAttemptState>((ref) {
  return ChallengeAttemptNotifier(ref);
});

class ChallengeAttemptNotifier extends StateNotifier<ChallengeAttemptState> {
  ChallengeAttemptNotifier(this.ref) : super(ChallengeAttemptState.initial());

  final Ref ref;
  final Map<String, ChallengeAttempt> _startedAttempts = {};

  Future<ChallengeAttempt?> startAttempt(String challengeId) async {
    final existing = _startedAttempts[challengeId];
    if (existing != null) {
      state = ChallengeAttemptState.initial().copyWith(attempt: existing);
      return existing;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      final attempt = await ref.read(challengeServiceProvider).startAttempt(challengeId);
      _startedAttempts[challengeId] = attempt;
      state = ChallengeAttemptState.initial().copyWith(attempt: attempt, loading: false);
      return attempt;
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      return null;
    }
  }

  void loadAttempt(ChallengeAttempt attempt) {
    _startedAttempts.putIfAbsent(attempt.challengeId, () => attempt);
    state = ChallengeAttemptState.initial().copyWith(attempt: attempt);
  }

  void selectChoice(String questionId, String choiceId) {
    final attempt = state.attempt;
    if (attempt == null) return;

    final updated = Map<String, String>.from(state.selectedAnswers);
    updated[questionId] = choiceId;
    state = state.copyWith(selectedAnswers: updated);
  }

  bool get isLastQuestion {
    final attempt = state.attempt;
    if (attempt == null) return true;
    return state.currentIndex >= attempt.questions.length - 1;
  }

  void nextQuestion() {
    final attempt = state.attempt;
    if (attempt == null) return;
    if (isLastQuestion) return;

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
    );
  }

  void reset() {
    state = ChallengeAttemptState.initial();
  }
}
