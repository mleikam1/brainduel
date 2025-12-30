import 'package:flutter/material.dart';

class AnswerFeedbackOverlay extends StatelessWidget {
  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.explanation,
    required this.correctAnswer,
    required this.onNext,
    this.isTimedOut = false,
  });

  final bool isCorrect;
  final String? explanation;
  final String correctAnswer;
  final VoidCallback onNext;
  final bool isTimedOut;

  @override
  Widget build(BuildContext context) {
    final statusText = isTimedOut
        ? 'Time\'s up!'
        : isCorrect
        ? 'Correct!'
        : 'Answer revealed';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 6),
            Text('Correct Answer: $correctAnswer'),
            if (explanation != null) ...[
              const SizedBox(height: 8),
              Text(explanation!),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: onNext, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}
