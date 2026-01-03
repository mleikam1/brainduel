import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../models/rankings_content.dart';
import '../state/rankings_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_card.dart';
import '../widgets/brain_duel_bottom_nav.dart';

class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(rankingsPeriodProvider);
    final scope = ref.watch(rankingsScopeProvider);
    final topicId = ref.watch(rankingsTopicProvider);
    final contentAsync = ref.watch(rankingsProvider);

    return BDAppScaffold(
      title: 'Rankings',
      subtitle: 'Arena standings',
      bottomNavigationBar: BrainDuelBottomNav(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
      child: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load rankings: $error')),
        data: (content) {
          final leaderboard = _resolveLeaderboard(content, scope, topicId);
          final selectedTopicId = _resolveTopicId(content, topicId);

          return ListView(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            children: [
              BDCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tier Progress', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      '${content.rankProgress.tier} → ${content.rankProgress.nextTier}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: content.rankProgress.progress.clamp(0.0, 1.0)),
                    const SizedBox(height: 8),
                    Text(
                      '${content.rankProgress.currentPoints}/${content.rankProgress.nextTierPoints} pts',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<RankingsPeriod>(
                segments: const [
                  ButtonSegment(value: RankingsPeriod.weekly, label: Text('Weekly')),
                  ButtonSegment(value: RankingsPeriod.monthly, label: Text('Monthly')),
                ],
                selected: {period},
                onSelectionChanged: (selection) {
                  ref.read(rankingsPeriodProvider.notifier).state = selection.first;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: RankingsScope.values.map((value) {
                  return ChoiceChip(
                    label: Text(_scopeLabel(value)),
                    selected: scope == value,
                    onSelected: (_) => ref.read(rankingsScopeProvider.notifier).state = value,
                  );
                }).toList(),
              ),
              if (scope == RankingsScope.topic) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTopicId,
                  decoration: const InputDecoration(labelText: 'Topic leaderboard'),
                  items: content.topicLeaderboards.keys
                      .map((id) => DropdownMenuItem(value: id, child: Text(id.toUpperCase())))
                      .toList(),
                  onChanged: (value) => ref.read(rankingsTopicProvider.notifier).state = value,
                ),
              ],
              const SizedBox(height: 16),
              Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...leaderboard.map((entry) => _LeaderboardRow(entry: entry)).toList(),
              const SizedBox(height: 20),
              Text('Duel History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...content.duelHistory.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BDCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          record.win ? Icons.emoji_events : Icons.close,
                          color: record.win
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(record.opponent, style: Theme.of(context).textTheme.titleSmall),
                              Text('${record.modeLabel} • ${record.scoreLine}'),
                            ],
                          ),
                        ),
                        Text(record.timeLabel, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  String _scopeLabel(RankingsScope scope) {
    switch (scope) {
      case RankingsScope.global:
        return 'Global';
      case RankingsScope.friends:
        return 'Friends';
      case RankingsScope.topic:
        return 'Topic';
    }
  }

  String _resolveTopicId(RankingsContent content, String? selected) {
    if (selected != null && content.topicLeaderboards.containsKey(selected)) {
      return selected;
    }
    return content.topicLeaderboards.keys.first;
  }

  List<LeaderboardEntry> _resolveLeaderboard(
    RankingsContent content,
    RankingsScope scope,
    String? topicId,
  ) {
    switch (scope) {
      case RankingsScope.global:
        return content.globalLeaderboard;
      case RankingsScope.friends:
        return content.friendsLeaderboard;
      case RankingsScope.topic:
        final id = _resolveTopicId(content, topicId);
        return content.topicLeaderboards[id] ?? content.globalLeaderboard;
    }
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final minutes = entry.time.inMinutes;
    final seconds = entry.time.inSeconds.remainder(60);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BDCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text('#${entry.rank}', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 12),
            BDAvatar(name: entry.name, radius: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(entry.name)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${entry.points} pts', style: Theme.of(context).textTheme.labelLarge),
                Text('${minutes}m ${seconds}s', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
