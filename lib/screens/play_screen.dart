import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/play_mode.dart';
import '../state/play_modes_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/brain_duel_bottom_nav.dart';

class PlayScreen extends ConsumerWidget {
  const PlayScreen({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  void _launchMode(BuildContext context, PlayMode mode) {
    final destination = mode.destination;
    switch (destination.type) {
      case PlayDestinationType.categories:
        context.pushNamed(TriviaApp.nameCategories);
        return;
      case PlayDestinationType.challenge:
        final challengeId = destination.challengeId ?? 'featured_global_01';
        context.pushNamed(
          TriviaApp.nameChallengeIntro,
          pathParameters: {'challengeId': challengeId},
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(playModesProvider);
    return BDAppScaffold(
      title: 'Play',
      subtitle: 'Choose your mode',
      bottomNavigationBar: BrainDuelBottomNav(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mode = modes[index];
          return BDCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _launchMode(context, mode),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mode.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (mode.ranked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Ranked',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(mode.description),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    BDStatPill(label: 'Risk', value: mode.riskLabel),
                    BDStatPill(label: 'Reward', value: mode.rewardLabel),
                  ],
                ),
                const SizedBox(height: 12),
                BDPrimaryButton(
                  label: mode.ctaLabel,
                  onPressed: () => _launchMode(context, mode),
                ),
                if (mode.id == 'async_duel') ...[
                  const SizedBox(height: 8),
                  BDSecondaryButton(
                    label: 'Find Friends',
                    onPressed: () => context.pushNamed(TriviaApp.nameFriends),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
