import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/home_challenge.dart';
import '../models/seasonal_event.dart';
import '../state/categories_provider.dart';
import '../state/home_feed_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/category_card.dart';
import '../widgets/challenge_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final homeFeedAsync = ref.watch(homeFeedProvider);
    final textScale = MediaQuery.textScaleFactorOf(context);
    final carouselHeight = (220 + (textScale - 1) * 96).clamp(220, 320).toDouble();
    final exploreHeight = (220 + (textScale - 1) * 96).clamp(220, 320).toDouble();

    return BDAppScaffold(
      title: 'Brain Duel',
      subtitle: 'Competitive trivia arena',
      actions: [
        IconButton(
          onPressed: () => context.pushNamed(TriviaApp.nameProfile),
          icon: const BDAvatar(name: 'Alex', radius: 18),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: BDCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Alex',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ranked streak: 4 wins',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        BDStatPill(label: 'Rank', value: 'Gold'),
                        BDStatPill(label: 'Season', value: '18'),
                        BDStatPill(label: 'Win %', value: '62'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: BDPrimaryButton(
                      label: 'Play Solo',
                      icon: Icons.play_arrow,
                      isExpanded: true,
                      onPressed: () => context.pushNamed(TriviaApp.nameCategories),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BDSecondaryButton(
                      label: 'Duel a Friend',
                      icon: Icons.people,
                      isExpanded: true,
                      onPressed: () => context.pushNamed(TriviaApp.nameFriends),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: homeFeedAsync.when(
                data: (homeFeed) {
                  final seasonalEvent = homeFeed.seasonalEvent;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Daily Challenges'),
                      const SizedBox(height: 12),
                      _ChallengeCarousel(
                        challenges: homeFeed.dailyChallenges,
                        height: carouselHeight,
                        onTap: (challengeId) => context.pushNamed(
                          TriviaApp.nameChallengeIntro,
                          pathParameters: {'challengeId': challengeId},
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (seasonalEvent != null) ...[
                        _SeasonalEventBanner(
                          event: seasonalEvent,
                          onTap: () => context.pushNamed(TriviaApp.nameSeasonalEvent),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _SectionHeader(title: 'Trending Public Challenges'),
                      const SizedBox(height: 12),
                      _ChallengeCarousel(
                        challenges: homeFeed.trendingChallenges,
                        height: carouselHeight,
                        onTap: (challengeId) => context.pushNamed(
                          TriviaApp.nameChallengeIntro,
                          pathParameters: {'challengeId': challengeId},
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Failed to load: $error',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Explore Topics',
                actionLabel: 'See all',
                onAction: () => context.pushNamed(TriviaApp.nameCategories),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: exploreHeight,
                child: categoriesAsync.when(
                  data: (categories) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final detail = ref.read(categoryDetailProvider(category));
                        return SizedBox(
                          width: 210,
                          child: CategoryCard(
                            category: category,
                            subtitle: detail.subtitle,
                            points: detail.points,
                            questionCount: detail.questionCount,
                            onTap: () => context.pushNamed(
                              TriviaApp.nameCategoryDetail,
                              extra: category.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load: $error',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: TextButton(
                onPressed: () => context.pushNamed(TriviaApp.nameSettings),
                child: const Text(
                  'Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasAction)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _ChallengeCarousel extends StatelessWidget {
  const _ChallengeCarousel({
    required this.challenges,
    required this.height,
    required this.onTap,
  });

  final List<HomeChallenge> challenges;
  final double height;
  final void Function(String challengeId) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return SizedBox(
            width: 210,
            child: ChallengeCard(
              challenge: challenge,
              onTap: () => onTap(challenge.id),
            ),
          );
        },
      ),
    );
  }
}

class _SeasonalEventBanner extends StatelessWidget {
  const _SeasonalEventBanner({
    required this.event,
    this.onTap,
  });

  final SeasonalEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BDCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrainDuelColors.glacier.withValues(alpha: 0.16),
              BrainDuelColors.neon.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: const BorderRadius.all(BrainDuelRadii.md),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: BrainDuelColors.ember.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.all(BrainDuelRadii.sm),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.emoji_events, color: BrainDuelColors.ember),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      BDStatPill(label: 'Reward', value: event.rewardLabel),
                      BDStatPill(label: 'Time', value: event.timeRemaining),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
