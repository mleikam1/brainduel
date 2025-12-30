import 'package:flutter/material.dart';
import '../models/trivia_session.dart';
import 'answer_option_button.dart';
import 'answer_feedback_overlay.dart';

class TriviaQuestionView extends StatelessWidget {
  const TriviaQuestionView({
    super.key,
    required this.session,
    required this.currentIndex,
    required this.selectedAnswerId,
    required this.isAnswered,
    required this.onSelectAnswer,
    required this.onNext,
  });

  final TriviaSession session;
  final int currentIndex;
  final String? selectedAnswerId;
  final bool isAnswered;
  final void Function(String answerId) onSelectAnswer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final q = session.questions[currentIndex];
    final correctAnswerId = q.answers.firstWhere((a) => a.correct).id;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${currentIndex + 1} of ${session.questions.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Text(
            q.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...q.answers.map((a) {
            final isSelected = selectedAnswerId == a.id;
            final showCorrectness = isAnswered;
            final isCorrect = a.id == correctAnswerId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerOptionButton(
                text: a.text,
                disabled: isAnswered,
                isSelected: isSelected,
                showCorrectness: showCorrectness,
                isCorrectAnswer: isCorrect,
                onTap: () => onSelectAnswer(a.id),
              ),
            );
          }),
          const Spacer(),
          if (isAnswered)
            AnswerFeedbackOverlay(
              isCorrect: selectedAnswerId == correctAnswerId,
              explanation: q.explanation,
              onNext: onNext,
            ),
        ],
      ),
    );
  }
}
