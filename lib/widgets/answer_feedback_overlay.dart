import 'package:flutter/material.dart';

class AnswerFeedbackOverlay extends StatelessWidget {
  const AnswerFeedbackOverlay({
    super.key,
    required this.isCorrect,
    required this.explanation,
    required this.onNext,
  });

  final bool isCorrect;
  final String? explanation;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isCorrect ? 'Correct!' : 'Not quite.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            if (explanation != null) ...[
              const SizedBox(height: 8),
              Text(explanation!),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: onNext, child: const Text('Next')),
          ],
        ),
      ),
    );
  }
}
