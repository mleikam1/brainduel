import 'package:flutter/material.dart';
import '../models/trivia_answer.dart';
import '../models/trivia_session.dart';
import '../state/trivia_session_provider.dart';
import 'bd_answer_option_tile.dart';
import 'bd_card.dart';

class TriviaQuestionView extends StatelessWidget {
  const TriviaQuestionView({
    super.key,
    required this.session,
    required this.currentIndex,
    required this.phase,
    required this.selectedAnswer,
    required this.onSelectAnswer,
  });

  final TriviaSession session;
  final int currentIndex;
  final QuestionPhase phase;
  final TriviaAnswer? selectedAnswer;
  final void Function(String answerId) onSelectAnswer;

  @override
  Widget build(BuildContext context) {
    final q = session.questions[currentIndex];
    final answers = q.displayAnswers;
    final showAnswers = phase != QuestionPhase.reading;
    final isAnswering = phase == QuestionPhase.answering;
    final isAnswered = phase == QuestionPhase.answered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BDCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (q.mediaUrl != null) ...[
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    ),
                    child: const Center(child: Icon(Icons.image, size: 36)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: showAnswers
              ? Column(
                  key: const ValueKey('answers'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...answers.map((a) {
                      final isSelected = selectedAnswer?.id == a.id;
                      BDAnswerState state = BDAnswerState.idle;

                      if (isAnswered && isSelected) {
                        state = selectedAnswer?.correct == true
                            ? BDAnswerState.correct
                            : BDAnswerState.incorrect;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BDAnswerOptionTile(
                          text: a.text,
                          state: state,
                          onTap: isAnswering ? () => onSelectAnswer(a.id) : null,
                        ),
                      );
                    }),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('hidden')),
        ),
      ],
    );
  }
}
