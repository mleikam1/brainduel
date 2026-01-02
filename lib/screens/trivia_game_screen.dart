import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/trivia_session_provider.dart';
import '../state/user_stats_provider.dart';
import '../state/subscription_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_progress_bar.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/trivia_question_view.dart';

class TriviaGameScreen extends ConsumerStatefulWidget {
  const TriviaGameScreen({super.key});

  @override
  ConsumerState<TriviaGameScreen> createState() => _TriviaGameScreenState();
}

class _TriviaGameScreenState extends ConsumerState<TriviaGameScreen> with TickerProviderStateMixin {
  String? categoryId;
  Timer? _readTimer;
  Timer? _answerTimer;
  Timer? _advanceTimer;
  static const int _readSeconds = 3;
  static const int _answerSeconds = 10;
  late final AnimationController _answerTimerController;
  bool _started = false;
  late final ProviderSubscription _sessionSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    categoryId ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void initState() {
    super.initState();
    _answerTimerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _answerSeconds),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      categoryId ??= ModalRoute.of(context)?.settings.arguments as String?;
      if (categoryId != null && !_started) {
        ref.read(triviaSessionProvider.notifier).startGame(categoryId!);
        _started = true;
      }
    });
    _sessionSubscription = ref.listenManual(triviaSessionProvider, (previous, next) {
      if (next.session != null &&
          (previous?.session == null || previous?.currentIndex != next.currentIndex)) {
        _startReadPhase();
      }
      if (next.isAnswered || next.isTimedOut) {
        _stopAnswerPhase();
        _scheduleAdvance();
      }
    });
  }

  @override
  void dispose() {
    _sessionSubscription.close();
    _cancelTimers();
    _answerTimerController.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _readTimer?.cancel();
    _answerTimer?.cancel();
    _advanceTimer?.cancel();
    _readTimer = null;
    _answerTimer = null;
    _advanceTimer = null;
  }

  void _startReadPhase() {
    _cancelTimers();
    _answerTimerController.stop();
    _answerTimerController.value = 0;
    _readTimer = Timer(const Duration(seconds: _readSeconds), () {
      if (!mounted) return;
      ref.read(triviaSessionProvider.notifier).startAnswerPhase();
      _startAnswerPhase();
    });
  }

  void _startAnswerPhase() {
    _answerTimerController.forward(from: 0);
    _answerTimer = Timer(const Duration(seconds: _answerSeconds), () {
      if (!mounted) return;
      ref.read(triviaSessionProvider.notifier).timeoutQuestion();
    });
  }

  void _stopAnswerPhase() {
    _answerTimer?.cancel();
    _answerTimer = null;
    _answerTimerController.stop();
  }

  void _scheduleAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final notifier = ref.read(triviaSessionProvider.notifier);
      if (notifier.isLastQuestion) {
        _finishGameAndGoToResults();
      } else {
        notifier.nextQuestion();
      }
    });
  }

  void _finishGameAndGoToResults() {
    final state = ref.read(triviaSessionProvider);
    final session = state.session!;
    final correct = state.correctAnswers;
    final total = session.questions.length;
    final points = state.points;

    ref.read(userStatsProvider.notifier).recordGame(
      questions: total,
      correct: correct,
      categoryId: session.categoryId,
    );

    context.goNamed(
      TriviaApp.namePostQuizAd,
      extra: {
        'categoryId': session.categoryId,
        'correct': correct,
        'total': total,
        'points': points,
        'startedAt': session.startedAt.toIso8601String(),
        'isPaidUser': ref.read(isPaidUserProvider),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triviaSessionProvider);
    final points = state.points;
    final isAnswerPhase = state.phase == TriviaQuestionPhase.answering;
    final isReadPhase = state.phase == TriviaQuestionPhase.reading;

    return BDAppScaffold(
      title: 'Solo Match',
      subtitle: state.session?.categoryId.toUpperCase(),
      child: state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to start game:\n${state.error}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (categoryId != null) {
                  ref.read(triviaSessionProvider.notifier).startGame(categoryId!);
                }
              },
              child: const Text('Retry'),
            )
          ],
        ),
      )
          : state.session == null
          ? const Center(child: Text('No session.'))
          : Padding(
              padding: const EdgeInsets.all(BrainDuelSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      BDStatPill(label: 'PTS', value: '$points', icon: Icons.bolt),
                      BDStatPill(label: 'Mode', value: 'Solo', icon: Icons.flash_on),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Question ${state.currentIndex + 1} of ${state.session!.questions.length}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  BDProgressBar(
                    value: (state.currentIndex + 1) / state.session!.questions.length,
                  ),
                  if (isAnswerPhase) ...[
                    const SizedBox(height: 12),
                    _AnswerTimerBar(controller: _answerTimerController),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      'Read the question first.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: TriviaQuestionView(
                        session: state.session!,
                        currentIndex: state.currentIndex,
                        selectedAnswerId: state.selectedAnswerId,
                        isAnswered: state.isAnswered,
                        isTimedOut: state.isTimedOut,
                        showAnswers: !isReadPhase,
                        onSelectAnswer: (id) => ref.read(triviaSessionProvider.notifier).selectAnswer(id),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Need hint? Coming soon.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _AnswerTimerBar extends StatelessWidget {
  const _AnswerTimerBar({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final remaining = (1 - controller.value).clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: LinearProgressIndicator(
              value: remaining,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}
