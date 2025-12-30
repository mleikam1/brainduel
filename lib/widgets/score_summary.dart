import 'package:flutter/material.dart';
import 'bd_card.dart';
import 'bd_stat_pill.dart';

class ScoreSummary extends StatelessWidget {
  const ScoreSummary({
    super.key,
    required this.correct,
    required this.total,
    required this.points,
    required this.timeTaken,
  });

  final int correct;
  final int total;
  final int points;
  final Duration timeTaken;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : (correct / total) * 100.0;
    final minutes = timeTaken.inMinutes;
    final seconds = timeTaken.inSeconds.remainder(60);

    return BDCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            '$points pts',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('$correct of $total correct • ${pct.toStringAsFixed(1)}% accuracy'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BDStatPill(label: 'Time', value: '${minutes}m ${seconds}s', icon: Icons.timer),
              BDStatPill(label: 'Correct', value: '$correct', icon: Icons.check_circle),
              BDStatPill(label: 'Total', value: '$total', icon: Icons.quiz),
            ],
          ),
        ],
      ),
    );
  }
}
