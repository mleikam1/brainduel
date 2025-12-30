import 'package:flutter/material.dart';

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({super.key, required this.correct, required this.total});

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (correct / total) * 100.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Score', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '$correct / $total',
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('${pct.toStringAsFixed(1)}% accuracy'),
          ],
        ),
      ),
    );
  }
}
