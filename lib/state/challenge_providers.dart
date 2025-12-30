import 'dart:async';
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
  final Map<String, ChallengeAnswerRecord> answerRecords;
  final QuestionPhase phase;
  final int remainingReadMs;
  final int remainingAnswerMs;

  const ChallengeAttemptState({
    required this.loading,
    required this.error,
    required this.attempt,
    required this.currentIndex,
    required this.answerRecords,
    required this.phase,
    required this.remainingReadMs,
    required this.remainingAnswerMs,
  });

  factory ChallengeAttemptState.initial() => const ChallengeAttemptState(
    loading: false,
    error: null,
    attempt: null,
    currentIndex: 0,
    answerRecords: {},
    phase: QuestionPhase.reading,
    remainingReadMs: ChallengeAttemptNotifier.readDurationMs,
    remainingAnswerMs: ChallengeAttemptNotifier.answerDurationMs,
  );

  ChallengeAttemptState copyWith({
    bool? loading,
    String? error,
    ChallengeAttempt? attempt,
    int? currentIndex,
    Map<String, ChallengeAnswerRecord>? answerRecords,
    QuestionPhase? phase,
    int? remainingReadMs,
    int? remainingAnswerMs,
  }) {
    return ChallengeAttemptState(
      loading: loading ?? this.loading,
      error: error,
      attempt: attempt ?? this.attempt,
      currentIndex: currentIndex ?? this.currentIndex,
      answerRecords: answerRecords ?? this.answerRecords,
      phase: phase ?? this.phase,
      remainingReadMs: remainingReadMs ?? this.remainingReadMs,
      remainingAnswerMs: remainingAnswerMs ?? this.remainingAnswerMs,
    );
  }
}

enum QuestionPhase { reading, answering, locked }

class ChallengeAnswerRecord {
  final int? choiceIndex;
  final String? choiceId;
  final int answerTimeMs;

  const ChallengeAnswerRecord({
    required this.choiceIndex,
    required this.choiceId,
    required this.answerTimeMs,
  });
}

final challengeAttemptProvider =
StateNotifierProvider<ChallengeAttemptNotifier, ChallengeAttemptState>((ref) {
  return ChallengeAttemptNotifier(ref);
});

class ChallengeAttemptNotifier extends StateNotifier<ChallengeAttemptState> {
  ChallengeAttemptNotifier(this.ref) : super(ChallengeAttemptState.initial());

  static const int readDurationMs = 3000;
  static const int answerDurationMs = 10000;

  final Ref ref;
  final Map<String, ChallengeAttempt> _startedAttempts = {};
  Timer? _timer;
  Stopwatch? _stopwatch;

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
    _startReadPhase();
  }

  void selectChoice(String questionId, String choiceId) {
    final attempt = state.attempt;
    if (attempt == null) return;
    if (state.phase != QuestionPhase.answering) return;

    final question = attempt.questions[state.currentIndex];
    if (question.id != questionId) return;
    if (state.answerRecords.containsKey(questionId)) return;

    final choiceIndex = question.choices.indexWhere((choice) => choice.id == choiceId);
    if (choiceIndex == -1) return;

    final answerTimeMs = _clampAnswerTime(_stopwatch?.elapsedMilliseconds ?? 0);
    _stopTimers();

    final updated = Map<String, ChallengeAnswerRecord>.from(state.answerRecords);
    updated[questionId] = ChallengeAnswerRecord(
      choiceIndex: choiceIndex,
      choiceId: choiceId,
      answerTimeMs: answerTimeMs,
    );
    state = state.copyWith(
      answerRecords: updated,
      phase: QuestionPhase.locked,
      remainingAnswerMs: (answerDurationMs - answerTimeMs).clamp(0, answerDurationMs),
    );
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
    if (state.phase != QuestionPhase.locked) return;

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      phase: QuestionPhase.reading,
      remainingReadMs: readDurationMs,
      remainingAnswerMs: answerDurationMs,
    );
    _startReadPhase();
  }

  void reset() {
    _stopTimers();
    state = ChallengeAttemptState.initial();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _startReadPhase() {
    _stopTimers();
    state = state.copyWith(
      phase: QuestionPhase.reading,
      remainingReadMs: readDurationMs,
      remainingAnswerMs: answerDurationMs,
    );
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final remaining = state.remainingReadMs - 100;
      if (remaining <= 0) {
        timer.cancel();
        _startAnswerPhase();
      } else {
        state = state.copyWith(remainingReadMs: remaining);
      }
    });
  }

  void _startAnswerPhase() {
    _stopTimers();
    _stopwatch = Stopwatch()..start();
    state = state.copyWith(
      phase: QuestionPhase.answering,
      remainingReadMs: 0,
      remainingAnswerMs: answerDurationMs,
    );
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final elapsed = _stopwatch?.elapsedMilliseconds ?? 0;
      final remaining = answerDurationMs - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _timeoutCurrentQuestion();
      } else {
        state = state.copyWith(remainingAnswerMs: remaining);
      }
    });
  }

  void _timeoutCurrentQuestion() {
    final attempt = state.attempt;
    if (attempt == null) return;
    final question = attempt.questions[state.currentIndex];
    if (state.answerRecords.containsKey(question.id)) return;
    _stopTimers();
    final updated = Map<String, ChallengeAnswerRecord>.from(state.answerRecords);
    updated[question.id] = const ChallengeAnswerRecord(
      choiceIndex: null,
      choiceId: null,
      answerTimeMs: answerDurationMs,
    );
    state = state.copyWith(
      answerRecords: updated,
      phase: QuestionPhase.locked,
      remainingAnswerMs: 0,
    );
  }

  void _stopTimers() {
    _timer?.cancel();
    _timer = null;
    _stopwatch?.stop();
    _stopwatch = null;
  }

  int _clampAnswerTime(int value) => value.clamp(0, answerDurationMs);
}
