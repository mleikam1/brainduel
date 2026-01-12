import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/auth_provider.dart';
import '../state/categories_provider.dart';
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

class TriviaGameLaunchArgs {
  const TriviaGameLaunchArgs({this.categoryId, this.gameId});

  final String? categoryId;
  final String? gameId;

  bool get isShared => gameId != null && gameId!.isNotEmpty;
}

class _TriviaGameScreenState extends ConsumerState<TriviaGameScreen> with TickerProviderStateMixin {
  TriviaGameLaunchArgs? _launchArgs;
  Timer? _readTimer;
  Timer? _answerTimer;
  Timer? _advanceTimer;
  static const int _readSeconds = 4;
  static const int _answerSeconds = 10;
  late final AnimationController _answerTimerController;
  bool _started = false;
  late final ProviderSubscription _sessionSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveLaunchArgs();
  }

  @override
  void initState() {
    super.initState();
    _answerTimerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _answerSeconds),
    );
    _sessionSubscription = ref.listenManual(triviaSessionProvider, (previous, next) {
      if (next.session != null &&
          (previous?.session == null || previous?.currentIndex != next.currentIndex)) {
        _startReadPhase();
      }
      if (next.phase == QuestionPhase.answered) {
        _stopAnswerPhase();
        _scheduleAdvance();
      }
    });
  }

  void _resolveLaunchArgs() {
    if (_launchArgs != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TriviaGameLaunchArgs) {
      _launchArgs = args;
    } else if (args is Map) {
      _launchArgs = TriviaGameLaunchArgs(
        categoryId: args['categoryId'] as String?,
        gameId: args['gameId'] as String?,
      );
    } else if (args is String) {
      _launchArgs = TriviaGameLaunchArgs(categoryId: args);
    }
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
    _advanceTimer = Timer(const Duration(seconds: 1), () {
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
    final notifier = ref.read(triviaSessionProvider.notifier);
    _cancelTimers();
    notifier.completeGame().then((result) {
      if (!mounted || result == null) return;
      final state = ref.read(triviaSessionProvider);
      final session = state.session!;
      final total = result.total ?? session.questionsSnapshot.length;
      final correct = result.correct ?? state.correctAnswers;
      final points = result.score;

      ref.read(userStatsProvider.notifier).recordGame(
        questions: total,
        correct: correct,
        categoryId: session.topicId,
      );

      context.goNamed(
        TriviaApp.namePostQuizAd,
        extra: {
          'categoryId': session.topicId,
          'correct': correct,
          'total': total,
          'points': points,
          'startedAt': state.startedAt?.toIso8601String(),
          'isPaidUser': ref.read(isPaidUserProvider),
        },
      );
    });
  }

  Future<void> _showAlreadyCompletedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz already completed'),
        content: const Text(
          'This quiz has already been completed. Each quiz can only be played once.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(triviaSessionProvider, (previous, next) {
      final wasShowing = previous?.showAlreadyCompletedModal ?? false;
      if (next.showAlreadyCompletedModal && !wasShowing) {
        _showAlreadyCompletedDialog();
        ref.read(triviaSessionProvider.notifier).dismissAlreadyCompletedModal();
      }
    });
    _resolveLaunchArgs();
    final launchArgs = _launchArgs;
    final userReady = ref.watch(userBootstrapReadyProvider);
    final categoriesReady =
        ref.watch(categoriesProvider).maybeWhen(data: (_) => true, orElse: () => false);
    if (!_started && launchArgs != null && userReady) {
      final shouldStart = launchArgs.isShared || categoriesReady;
      if (shouldStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _started) return;
          final notifier = ref.read(triviaSessionProvider.notifier);
          if (launchArgs.isShared) {
            notifier.loadGame(launchArgs.gameId!);
          } else if (launchArgs.categoryId != null) {
            notifier.startGame(launchArgs.categoryId!);
          }
          _started = true;
        });
      }
    }
    final state = ref.watch(triviaSessionProvider);
    final points = state.points;
    final isAnswerPhase = state.phase == QuestionPhase.answering;

    return WillPopScope(
      onWillPop: () async => !state.hasAnsweredAny && !state.isSubmitting && !state.isLocked,
      child: BDAppScaffold(
        title: 'Solo Match',
        subtitle: state.session?.topicId.toUpperCase(),
        leading: state.hasAnsweredAny || state.isLocked ? const SizedBox.shrink() : null,
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
                            final launchArgs = _launchArgs;
                            if (launchArgs == null) return;
                            final notifier = ref.read(triviaSessionProvider.notifier);
                            if (launchArgs.isShared) {
                              notifier.loadGame(launchArgs.gameId!);
                            } else if (launchArgs.categoryId != null) {
                              notifier.startGame(launchArgs.categoryId!);
                            }
                          },
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  )
                : state.session == null
                    ? const Center(child: Text('No session.'))
                    : state.isSubmitting
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(
                                  'Hang tight while we collect your score and rank!',
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : AbsorbPointer(
                            absorbing: state.isSubmitting,
                            child: Padding(
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
                                    'Question ${state.currentIndex + 1} of ${state.session!.questionsSnapshot.length}',
                                    style: Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  BDProgressBar(
                                    value: (state.currentIndex + 1) / state.session!.questionsSnapshot.length,
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
                                        phase: state.phase,
                                        selectedIndex: state.selectedIndex,
                                        onSelectAnswer: (index) => ref
                                            .read(triviaSessionProvider.notifier)
                                            .selectAnswer(index),
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
