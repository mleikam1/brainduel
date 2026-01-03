import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/categories_provider.dart';
import '../state/user_stats_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';

class ProfileStatsScreen extends ConsumerWidget {
  const ProfileStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];

    String categoryName(String id) {
      if (categories.isEmpty) return id;
      return categories.firstWhere((c) => c.id == id, orElse: () => categories.first).title;
    }

    return BDAppScaffold(
      title: 'Profile',
      subtitle: 'Your competitive stats',
      child: ListView(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        children: [
          BDCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const BDAvatar(name: 'Matt Leikam', radius: 28),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Matt Leikam', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Rank Tier: Gold II', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BDStatPill(label: 'Points', value: '${stats.totalPoints}'),
              BDStatPill(label: 'Accuracy', value: '${(stats.accuracy * 100).toStringAsFixed(1)}%'),
              BDStatPill(label: 'Games', value: '${stats.gamesPlayed}'),
              BDStatPill(label: 'Best Streak', value: '${stats.bestStreak}'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Performance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          BDCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                _PerformanceRow(label: 'Accuracy', value: '${(stats.accuracy * 100).toStringAsFixed(0)}%'),
                const SizedBox(height: 10),
                _PerformanceRow(label: 'Games Played', value: '${stats.gamesPlayed}'),
                const SizedBox(height: 10),
                _PerformanceRow(label: 'Questions', value: '${stats.questionsAnswered}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Recent Games', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (stats.recentGames.isEmpty)
            BDCard(
              child: Text('Play a match to build your history.'),
            )
          else
            Column(
              children: stats.recentGames.map((game) {
                final date = '${game.playedAt.month}/${game.playedAt.day}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BDCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.timeline),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(categoryName(game.categoryId), style: Theme.of(context).textTheme.titleSmall),
                              Text('Played $date • ${game.correct}/${game.total} correct'),
                            ],
                          ),
                        ),
                        Text('${(game.correct / game.total * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          BDCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Terms of Service'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Support'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.read(userStatsProvider.notifier).reset(),
            child: const Text('Reset Stats'),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
