import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/challenge.dart';
import '../state/ad_provider.dart';
import '../state/challenge_providers.dart';
import '../state/subscription_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeAttemptProvider);
    final attempt = state.attempt ?? widget.attempt;
    final question = attempt.questions[state.currentIndex];
    final answerRecord = state.answerRecords[question.id];
    final selectedChoiceId = answerRecord?.choiceId;
    final isLastQuestion = state.currentIndex >= attempt.questions.length - 1;
    final isReadPhase = state.phase == QuestionPhase.reading;
    final isAnswerPhase = state.phase == QuestionPhase.answering;
    final isLocked = state.phase == QuestionPhase.locked;
    final isSubmitting = state.submitting;
    final isSubmitted = state.submitted;
    final remainingSeconds = isReadPhase
        ? (state.remainingReadMs / 1000).ceil()
        : (state.remainingAnswerMs / 1000).ceil();
    final phaseLabel = isReadPhase ? 'Read' : 'Time';

    return BDAppScaffold(
      title: 'Challenge Run',
      subtitle: attempt.challengeId,
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BDStatPill(
                  label: 'Qs',
                  value: '${state.currentIndex + 1}/${attempt.questions.length}',
                ),
                BDStatPill(label: 'Mode', value: 'Challenge'),
                BDStatPill(label: phaseLabel, value: '${remainingSeconds}s'),
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
                      final isSelected = selectedChoiceId == choice.id;
                      final isDisabled = !isAnswerPhase;
                      final stateValue = isSelected
                          ? BDAnswerState.selected
                          : isDisabled
                              ? BDAnswerState.disabled
                              : BDAnswerState.idle;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BDAnswerOptionTile(
                          text: choice.text,
                          state: stateValue,
                          onTap: isAnswerPhase && !isLocked
                              ? () => ref
                                  .read(challengeAttemptProvider.notifier)
                                  .selectChoice(question.id, choice.id)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: !isLocked || isSubmitting || isSubmitted
                  ? null
                  : () async {
                      if (isLastQuestion) {
                        final notifier = ref.read(challengeAttemptProvider.notifier);
                        final result = await notifier.submitAttempt();
                        if (!mounted || result == null) {
                          if (mounted) {
                            final submissionError =
                                ref.read(challengeAttemptProvider).submissionError;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  submissionError ?? 'Unable to submit attempt. Try again.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        final isPaid = ref.read(isPaidUserProvider);
                        if (!isPaid) {
                          await ref.read(adServiceProvider).showInterstitial(context);
                        }
                        if (!mounted) return;
                        context.goNamed(
                          TriviaApp.nameResults,
                          extra: {'challengeResult': result},
                        );
                      } else {
                        ref.read(challengeAttemptProvider.notifier).nextQuestion();
                      }
                    },
              child: Text(
                isLastQuestion
                    ? (isSubmitting ? 'Submitting...' : 'Submit Attempt')
                    : 'Next Question',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
