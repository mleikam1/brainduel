import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/home_challenge.dart';
import '../state/home_feed_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';

class SeasonalEventScreen extends ConsumerWidget {
  const SeasonalEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeFeedAsync = ref.watch(homeFeedProvider);

    return homeFeedAsync.when(
      loading: () => const BDAppScaffold(
        title: 'Seasonal Event',
        subtitle: 'Loading event',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => BDAppScaffold(
        title: 'Seasonal Event',
        subtitle: 'Unable to load',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load event: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.refresh(homeFeedProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (homeFeed) {
        final event = homeFeed.seasonalEvent;
        if (event == null) {
          return const BDAppScaffold(
            title: 'Seasonal Event',
            subtitle: 'No active event',
            child: Center(child: Text('No seasonal events are live right now.')),
          );
        }

        return BDAppScaffold(
          title: event.title,
          subtitle: event.timeRemaining,
          child: Padding(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            child: ListView(
              children: [
                BDCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          BDStatPill(label: 'Reward', value: event.rewardLabel),
                          BDStatPill(label: 'Time', value: event.timeRemaining),
                          const BDStatPill(label: 'Status', value: 'Active'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Event Challenges',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (event.challenges.isEmpty)
                  const Text('New challenges drop soon. Check back later!')
                else
                  ...event.challenges.map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _EventChallengeCard(
                        challenge: challenge,
                        onTap: () => context.pushNamed(
                          TriviaApp.nameChallengeIntro,
                          pathParameters: {'challengeId': challenge.id},
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EventChallengeCard extends StatelessWidget {
  const _EventChallengeCard({
    required this.challenge,
    required this.onTap,
  });

  final HomeChallenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BDCard(
      onTap: onTap,
      // Overflow-safe card layout: shrink-wrapped column with wrapping badges
      // so the card can grow vertically in lists.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(
                  challenge.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (challenge.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              challenge.subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  challenge.timeRemaining,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              BDStatPill(label: 'Qs', value: '${challenge.questionCount}'),
              BDStatPill(label: 'Pts', value: '${challenge.points}'),
            ],
          ),
        ],
      ),
    );
  }
}
