import 'package:flutter/material.dart';
import '../models/trivia_session.dart';
import 'answer_feedback_overlay.dart';
import 'bd_answer_option_tile.dart';
import 'bd_card.dart';

class TriviaQuestionView extends StatelessWidget {
  const TriviaQuestionView({
    super.key,
    required this.session,
    required this.currentIndex,
    required this.selectedAnswerId,
    required this.isAnswered,
    required this.onSelectAnswer,
    required this.onNext,
    required this.isTimedOut,
  });

  final TriviaSession session;
  final int currentIndex;
  final String? selectedAnswerId;
  final bool isAnswered;
  final void Function(String answerId) onSelectAnswer;
  final VoidCallback onNext;
  final bool isTimedOut;

  @override
  Widget build(BuildContext context) {
    final q = session.questions[currentIndex];
    final correctAnswerId = q.answers.firstWhere((a) => a.correct).id;

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
        ...q.answers.map((a) {
          final isSelected = selectedAnswerId == a.id;
          final isCorrect = a.id == correctAnswerId;
          BDAnswerState state = BDAnswerState.idle;

          if (isAnswered || isTimedOut) {
            if (isCorrect) {
              state = BDAnswerState.correct;
            } else if (isSelected && !isCorrect) {
              state = BDAnswerState.incorrect;
            } else {
              state = BDAnswerState.disabled;
            }
          } else if (isSelected) {
            state = BDAnswerState.selected;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BDAnswerOptionTile(
              text: a.text,
              state: state,
              onTap: (isAnswered || isTimedOut) ? null : () => onSelectAnswer(a.id),
            ),
          );
        }),
        if (isAnswered || isTimedOut) ...[
          const SizedBox(height: 8),
          AnswerFeedbackOverlay(
            isCorrect: selectedAnswerId == correctAnswerId,
            explanation: q.explanation,
            correctAnswer: q.answers.firstWhere((a) => a.correct).text,
            isTimedOut: isTimedOut,
            onNext: onNext,
          ),
        ],
      ],
    );
  }
}
