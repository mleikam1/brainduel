import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/challenge.dart';
import '../state/challenge_providers.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_answer_option_tile.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_progress_bar.dart';
import '../widgets/bd_stat_pill.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key, required this.attempt});

  final ChallengeAttempt attempt;

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      ref.read(challengeAttemptProvider.notifier).loadAttempt(widget.attempt);
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeAttemptProvider);
    final attempt = state.attempt ?? widget.attempt;
    final question = attempt.questions[state.currentIndex];
    final selectedChoiceId = state.selectedAnswers[question.id];
    final isLastQuestion = state.currentIndex >= attempt.questions.length - 1;

    return BDAppScaffold(
      title: 'Challenge Run',
      subtitle: attempt.challengeId,
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BDStatPill(
                  label: 'Qs',
                  value: '${state.currentIndex + 1}/${attempt.questions.length}',
                ),
                const SizedBox(width: 8),
                BDStatPill(label: 'Mode', value: 'Challenge'),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${state.currentIndex + 1} of ${attempt.questions.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            BDProgressBar(
              value: (state.currentIndex + 1) / attempt.questions.length,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BDCard(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        question.prompt,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...question.choices.map((choice) {
                      final stateValue = selectedChoiceId == choice.id
                          ? BDAnswerState.selected
                          : BDAnswerState.idle;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BDAnswerOptionTile(
                          text: choice.text,
                          state: stateValue,
                          onTap: () => ref
                              .read(challengeAttemptProvider.notifier)
                              .selectChoice(question.id, choice.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (isLastQuestion) {
                  context.goNamed(TriviaApp.nameHome);
                } else {
                  ref.read(challengeAttemptProvider.notifier).nextQuestion();
                }
              },
              child: Text(
                isLastQuestion ? 'Submit Attempt' : 'Next Question',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
