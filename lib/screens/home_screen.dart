import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/category.dart';
import '../models/home_dashboard.dart';
import '../state/home_dashboard_provider.dart';
import '../state/home_feed_provider.dart';
import '../state/quiz_controller.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/brain_duel_bottom_nav.dart';
import '../widgets/category_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final seasonalAsync = ref.watch(homeFeedProvider);
    final sessionState = ref.watch(quizControllerProvider);
    final showResume = sessionState.session != null &&
        !(sessionState.isAnswered && ref.read(quizControllerProvider.notifier).isLastQuestion);

    return BDAppScaffold(
      title: 'Brain Duel',
      subtitle: 'Daily competitive grind',
      actions: [
        IconButton(
          onPressed: () => context.pushNamed(TriviaApp.nameSettings),
          icon: const Icon(Icons.settings),
        ),
      ],
      bottomNavigationBar: BrainDuelBottomNav(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load home: $error')),
        data: (dashboard) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: _DailyChallengeCard(dashboard: dashboard),
                ),
              ),
              if (showResume)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: BDCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_fill),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resume last session',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'Pick up where you left off.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          BDPrimaryButton(
                            label: 'Resume',
                            onPressed: () => context.pushNamed(TriviaApp.nameGame),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'New & Updated Packs',
                    actionLabel: 'See all',
                    onAction: () => context.pushNamed(TriviaApp.nameCategories),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: _PackRail(packs: dashboard.newAndUpdatedPacks),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final row = dashboard.personalizedRows[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                            child: Text(
                              row.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PackRail(packs: row.packs),
                        ],
                      ),
                    );
                  },
                  childCount: dashboard.personalizedRows.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Limited-Time Packs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: seasonalAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => Text('Unable to load events: $error'),
                    data: (feed) {
                      final event = feed.seasonalEvent;
                      if (event == null) {
                        return const Text('No events live right now.');
                      }
                      return Column(
                        children: event.challenges.map((challenge) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BDCard(
                              padding: const EdgeInsets.all(16),
                              onTap: () => context.pushNamed(
                                TriviaApp.nameChallengeIntro,
                                pathParameters: {'challengeId': challenge.id},
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          challenge.badge,
                                          style: Theme.of(context).textTheme.labelLarge,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        challenge.timeRemaining,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    challenge.title,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(challenge.subtitle),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      BDStatPill(
                                        label: 'Qs',
                                        value: '${challenge.questionCount}',
                                      ),
                                      const SizedBox(width: 8),
                                      BDStatPill(
                                        label: 'Pts',
                                        value: '${challenge.points}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Monetization hook: limited-time packs can be boosted or featured here.
                                  BDPrimaryButton(
                                    label: 'Enter Event',
                                    onPressed: () => context.pushNamed(
                                      TriviaApp.nameChallengeIntro,
                                      pathParameters: {'challengeId': challenge.id},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final daily = dashboard.dailyChallenge;
    return BDCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 20),
              const SizedBox(width: 8),
              Text(
                'Daily Challenge',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              BDStatPill(label: 'Streak', value: '${daily.streak}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            daily.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(daily.subtitle),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BDStatPill(label: 'Qs', value: '${daily.questionCount}'),
              BDStatPill(label: 'Pts', value: '${daily.points}'),
              BDStatPill(label: 'Ends', value: daily.timeRemaining),
            ],
          ),
          const SizedBox(height: 14),
          BDPrimaryButton(
            label: 'Play Daily',
            isExpanded: true,
            onPressed: () => context.pushNamed(
              TriviaApp.nameChallengeIntro,
              pathParameters: {'challengeId': daily.id},
            ),
          ),
        ],
      ),
    );
  }
}

class _PackRail extends StatelessWidget {
  const _PackRail({required this.packs});

  final List<Category> packs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final category = packs[index];
          return SizedBox(
            width: 210,
            child: CategoryCard(
              category: category,
              onTap: () => context.pushNamed(
                TriviaApp.nameGame,
                extra: {'categoryId': category.id},
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: packs.length,
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
          ),
        ),
        if (hasAction)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
