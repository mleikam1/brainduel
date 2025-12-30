import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_stats_provider.dart';
import '../widgets/app_scaffold.dart';

class ProfileStatsScreen extends ConsumerWidget {
  const ProfileStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);

    return AppScaffold(
      title: 'Profile / Stats',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatTile(label: 'Games Played', value: '${stats.gamesPlayed}'),
            _StatTile(label: 'Questions Answered', value: '${stats.questionsAnswered}'),
            _StatTile(label: 'Correct Answers', value: '${stats.correctAnswers}'),
            _StatTile(label: 'Accuracy', value: '${(stats.accuracy * 100).toStringAsFixed(1)}%'),
            const Spacer(),
            TextButton(
              onPressed: () => ref.read(userStatsProvider.notifier).reset(),
              child: const Text('Reset Stats'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
