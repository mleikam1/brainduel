import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/profile_insights_provider.dart';
import '../state/subscription_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/brain_duel_bottom_nav.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(profileInsightsProvider);
    final isPaidUser = ref.watch(isPaidUserProvider);

    return BDAppScaffold(
      title: 'Profile',
      subtitle: 'Competitive résumé',
      bottomNavigationBar: BrainDuelBottomNav(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
      child: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load profile: $error')),
        data: (insights) {
          return ListView(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            children: [
              BDCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    BDAvatar(name: insights.displayName, radius: 28),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(insights.displayName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('Rank Tier: ${insights.rankTier}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Lifetime Stats', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  BDStatPill(label: 'Points', value: '${insights.lifetimePoints}'),
                  BDStatPill(label: 'Accuracy', value: '${(insights.accuracy * 100).toStringAsFixed(1)}%'),
                  BDStatPill(label: 'Games', value: '${insights.gamesPlayed}'),
                  BDStatPill(label: 'Questions', value: '${insights.questionsAnswered}'),
                ],
              ),
              const SizedBox(height: 20),
              Text('Accuracy by Topic', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (insights.topicAccuracies.isEmpty)
                const Text('Play a few matches to unlock topic accuracy.')
              else
                BDCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: insights.topicAccuracies.map((topic) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(topic.topicName)),
                                Text('${(topic.accuracy * 100).toStringAsFixed(0)}%'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: topic.accuracy),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),
              Text('Best Categories', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insights.bestTopics.map((topic) {
                  return BDStatPill(
                    label: topic.topicName,
                    value: '${(topic.accuracy * 100).toStringAsFixed(0)}%',
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Weakest Categories', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insights.weakestTopics.map((topic) {
                  return BDStatPill(
                    label: topic.topicName,
                    value: '${(topic.accuracy * 100).toStringAsFixed(0)}%',
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Streaks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              BDCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Streak', style: Theme.of(context).textTheme.bodySmall),
                        Text('${insights.currentStreak} wins', style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Best Streak', style: Theme.of(context).textTheme.bodySmall),
                        Text('${insights.bestStreak} wins', style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Badges & Achievements', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: insights.badges.map((badge) {
                  return SizedBox(
                    width: 150,
                    child: BDCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(badge.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 6),
                          Text(badge.title, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(badge.description, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Subscription', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              BDCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPaidUser ? 'Brain Duel Pro' : 'Free Access'),
                          Text(
                            isPaidUser
                                ? 'Ad-free results and premium challenges unlocked.'
                                : 'Upgrade to remove ads and unlock pro challenges.',
                          ),
                        ],
                      ),
                    ),
                    // Monetization hook: subscription management CTA belongs here.
                    TextButton(
                      onPressed: isPaidUser ? null : () {},
                      child: Text(isPaidUser ? 'Active' : 'Upgrade'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
