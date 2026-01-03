import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../models/challenge_answer_record.dart';
import '../models/challenge_result.dart';
import '../models/rematch.dart';
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
  final String? notice;
  final ChallengeAttempt? attempt;
  final bool submitting;
  final bool submitted;
  final String? submissionError;
  final int currentIndex;
  final Map<String, ChallengeAnswerRecord> answerRecords;
  final QuestionPhase phase;
  final int remainingReadMs;
  final int remainingAnswerMs;

  const ChallengeAttemptState({
    required this.loading,
    required this.error,
    required this.notice,
    required this.attempt,
    required this.submitting,
    required this.submitted,
    required this.submissionError,
    required this.currentIndex,
    required this.answerRecords,
    required this.phase,
    required this.remainingReadMs,
    required this.remainingAnswerMs,
  });

  factory ChallengeAttemptState.initial() => const ChallengeAttemptState(
    loading: false,
    error: null,
    notice: null,
    attempt: null,
    submitting: false,
    submitted: false,
    submissionError: null,
    currentIndex: 0,
    answerRecords: {},
    phase: QuestionPhase.reading,
    remainingReadMs: ChallengeAttemptNotifier.readDurationMs,
    remainingAnswerMs: ChallengeAttemptNotifier.answerDurationMs,
  );

  ChallengeAttemptState copyWith({
    bool? loading,
    String? error,
    String? notice,
    ChallengeAttempt? attempt,
    bool? submitting,
    bool? submitted,
    String? submissionError,
    int? currentIndex,
    Map<String, ChallengeAnswerRecord>? answerRecords,
    QuestionPhase? phase,
    int? remainingReadMs,
    int? remainingAnswerMs,
  }) {
    return ChallengeAttemptState(
      loading: loading ?? this.loading,
      error: error,
      notice: notice,
      attempt: attempt ?? this.attempt,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      submissionError: submissionError,
      currentIndex: currentIndex ?? this.currentIndex,
      answerRecords: answerRecords ?? this.answerRecords,
      phase: phase ?? this.phase,
      remainingReadMs: remainingReadMs ?? this.remainingReadMs,
      remainingAnswerMs: remainingAnswerMs ?? this.remainingAnswerMs,
    );
  }
}

enum QuestionPhase { reading, answering, locked }

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
      state = ChallengeAttemptState.initial().copyWith(
        attempt: existing,
        notice: 'Attempt already started. Resume when you\'re ready.',
      );
      return existing;
    }

    state = state.copyWith(loading: true, error: null, notice: null);
    try {
      final attempt = await ref.read(challengeServiceProvider).startAttempt(challengeId);
      _startedAttempts[challengeId] = attempt;
      state = ChallengeAttemptState.initial().copyWith(attempt: attempt, loading: false);
      return attempt;
    } on ChallengeExpiredException catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'This challenge expired at ${e.expiresAt.toLocal()}.',
      );
      return null;
    } on ChallengeRateLimitException catch (e) {
      final seconds = e.retryAfter?.inSeconds ?? 0;
      state = state.copyWith(
        loading: false,
        error: 'Too many attempts. Try again in ${seconds}s.',
      );
      return null;
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

  bool get canSubmit {
    return state.phase == QuestionPhase.locked && isLastQuestion && !state.submitting;
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

  Future<ChallengeResult?> submitAttempt() async {
    final attempt = state.attempt;
    if (attempt == null) return null;
    if (state.submitting || state.submitted) return null;
    state = state.copyWith(submitting: true, submissionError: null);
    try {
      final result = await ref.read(challengeServiceProvider).submitAttempt(
        attempt: attempt,
        answers: state.answerRecords,
      );
      state = state.copyWith(submitting: false, submitted: true);
      return result;
    } on ChallengeRateLimitException catch (e) {
      final seconds = e.retryAfter?.inSeconds ?? 0;
      state = state.copyWith(
        submitting: false,
        submissionError: 'You\'re answering too fast. Retry in ${seconds}s.',
      );
      return null;
    } catch (e) {
      state = state.copyWith(submitting: false, submissionError: e.toString());
      return null;
    }
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

enum RematchStatus { idle, requesting, pending, ready, error }

class RematchState {
  final String? challengeId;
  final RematchStatus status;
  final RematchRequest? request;
  final String? error;

  const RematchState({
    required this.challengeId,
    required this.status,
    required this.request,
    required this.error,
  });

  factory RematchState.initial() => const RematchState(
        challengeId: null,
        status: RematchStatus.idle,
        request: null,
        error: null,
      );

  RematchState copyWith({
    String? challengeId,
    RematchStatus? status,
    RematchRequest? request,
    String? error,
  }) {
    return RematchState(
      challengeId: challengeId ?? this.challengeId,
      status: status ?? this.status,
      request: request ?? this.request,
      error: error,
    );
  }
}

final rematchProvider = StateNotifierProvider.family<RematchNotifier, RematchState, String>((ref, challengeId) {
  return RematchNotifier(ref, challengeId);
});

class RematchNotifier extends StateNotifier<RematchState> {
  RematchNotifier(this.ref, this.challengeId)
      : super(
          RematchState.initial().copyWith(challengeId: challengeId),
        );

  final Ref ref;
  final String challengeId;
  int _rematchCount = 0;

  Future<void> requestRematch() async {
    final activeChallengeId = state.challengeId ?? challengeId;
    state = state.copyWith(status: RematchStatus.requesting, error: null);
    try {
      final request = await ref.read(challengeServiceProvider).createRematchRequest(
            originalChallengeId: activeChallengeId,
            rematchIndex: _rematchCount,
          );
      _rematchCount += 1;
      state = state.copyWith(
        status: RematchStatus.pending,
        request: request,
      );
    } catch (e) {
      state = state.copyWith(status: RematchStatus.error, error: e.toString());
    }
  }

  void acceptForChallenger() {
    final request = state.request;
    if (request == null) return;
    final updated = request.copyWith(challengerAccepted: true);
    _applyAcceptance(updated);
  }

  void acceptForOpponent() {
    final request = state.request;
    if (request == null) return;
    final updated = request.copyWith(opponentAccepted: true);
    _applyAcceptance(updated);
  }

  String? consumeReadyRematchId() {
    final request = state.request;
    if (state.status != RematchStatus.ready || request == null) return null;
    final rematchId = request.rematchChallengeId;
    state = RematchState.initial().copyWith(challengeId: state.challengeId);
    return rematchId;
  }

  void _applyAcceptance(RematchRequest updated) {
    final ready = updated.challengerAccepted && updated.opponentAccepted;
    state = state.copyWith(
      request: updated,
      status: ready ? RematchStatus.ready : RematchStatus.pending,
    );
  }
}
