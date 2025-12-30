import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../state/trivia_session_provider.dart';
import '../state/user_stats_provider.dart';
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

class _TriviaGameScreenState extends ConsumerState<TriviaGameScreen> {
  String? categoryId;
  Timer? _timer;
  static const int _questionSeconds = 40;
  int _remainingSeconds = _questionSeconds;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    categoryId ??= ModalRoute.of(context)?.settings.arguments as String?;
    if (categoryId != null && !_started) {
      ref.read(triviaSessionProvider.notifier).startGame(categoryId!);
      _started = true;
    }
  }

  @override
  void initState() {
    super.initState();
    ref.listen(triviaSessionProvider, (previous, next) {
      if (next.session != null && previous?.currentIndex != next.currentIndex) {
        _resetTimer();
      }
      if (next.isAnswered || next.isTimedOut) {
        _stopTimer();
      }
    });
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() => _remainingSeconds = _questionSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        ref.read(triviaSessionProvider.notifier).timeoutQuestion();
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _finishGameAndGoToResults() {
    final state = ref.read(triviaSessionProvider);
    final session = state.session!;
    final correct = state.score;
    final total = session.questions.length;

    ref.read(userStatsProvider.notifier).recordGame(
      questions: total,
      correct: correct,
      categoryId: session.categoryId,
    );

    Navigator.of(context).pushReplacementNamed(
      TriviaApp.routeResults,
      arguments: {
        'categoryId': session.categoryId,
        'correct': correct,
        'total': total,
        'startedAt': session.startedAt.toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(triviaSessionProvider);
    final points = state.score * 100;
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

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
            Row(
              children: [
                BDStatPill(label: 'PTS', value: '$points', icon: Icons.bolt),
                const SizedBox(width: 8),
                BDStatPill(label: 'Mode', value: 'Solo', icon: Icons.flash_on),
                const Spacer(),
                BDStatPill(label: 'Time', value: '$minutes:$seconds', icon: Icons.timer),
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
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: TriviaQuestionView(
                  session: state.session!,
                  currentIndex: state.currentIndex,
                  selectedAnswerId: state.selectedAnswerId,
                  isAnswered: state.isAnswered,
                  isTimedOut: state.isTimedOut,
                  onSelectAnswer: (id) => ref.read(triviaSessionProvider.notifier).selectAnswer(id),
                  onNext: () {
                    final notifier = ref.read(triviaSessionProvider.notifier);
                    if (notifier.isLastQuestion) {
                      _finishGameAndGoToResults();
                    } else {
                      notifier.nextQuestion();
                    }
                  },
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
