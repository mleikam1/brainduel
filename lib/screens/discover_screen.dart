import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/discover_content.dart';
import '../state/category_progress_provider.dart';
import '../state/discover_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../utils/category_icon_mapper.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/brain_duel_bottom_nav.dart';
import '../widgets/category_completion_badge.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(discoverContentProvider);
    final filter = ref.watch(discoverFilterProvider);
    final notifier = ref.read(discoverFilterProvider.notifier);
    final completionMap = ref.watch(categoryCompletionMapProvider);

    return BDAppScaffold(
      title: 'Discover',
      subtitle: 'Deep catalog of topics',
      bottomNavigationBar: BrainDuelBottomNav(
        currentIndex: currentIndex,
        onTap: onTabSelected,
      ),
      child: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load discover: $error')),
        data: (content) {
          final filtered = _applyFilter(content.topics, filter);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search topics and packs',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: notifier.updateQuery,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _DifficultyChip(
                        label: 'All',
                        selected: filter.difficulty == null,
                        onSelected: () => notifier.updateDifficulty(null),
                      ),
                      ...DiscoverDifficulty.values.map((difficulty) {
                        return _DifficultyChip(
                          label: _difficultyLabel(difficulty),
                          selected: filter.difficulty == difficulty,
                          onSelected: () => notifier.updateDifficulty(difficulty),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Editorial Collections',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final collection = content.collections[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BDCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(collection.description),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: collection.topicIds.map((topicId) {
                                  final topic = content.topics.firstWhere(
                                    (item) => item.category.id == topicId,
                                    orElse: () => content.topics.first,
                                  );
                                  return BDStatPill(
                                    label: topic.category.title,
                                    value: _difficultyLabel(topic.difficulty),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: content.collections.length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Sponsored & Creator Packs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: content.topics
                        .where((topic) => content.sponsoredTopicIds.contains(topic.category.id))
                        .map((topic) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
                                    width: 1.2,
                                  ),
                                ),
                                child: BDCard(
                                  padding: const EdgeInsets.all(16),
                                  onTap: () => context.pushNamed(
                                    TriviaApp.nameGame,
                                    extra: {'categoryId': topic.category.id},
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(CategoryIconMapper.forCategory(topic.category)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              topic.category.title,
                                              style: Theme.of(context).textTheme.titleSmall,
                                            ),
                                            Text('Creator spotlight • ${topic.subtitle}'),
                                          ],
                                        ),
                                      ),
                                      // Monetization hook: prioritize placements for sponsored packs here.
                                      const Text('Sponsored'),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Topic Catalog',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                sliver: filtered.isEmpty
                    ? const SliverToBoxAdapter(child: Text('No topics match your filters.'))
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final topic = filtered[index];
                            return _DiscoverTopicCard(
                              topic: topic,
                              completedThisWeek: completionMap[topic.category.id] ?? false,
                            );
                          },
                          childCount: filtered.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
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

  List<DiscoverTopic> _applyFilter(List<DiscoverTopic> topics, DiscoverFilter filter) {
    final query = filter.query.toLowerCase();
    return topics.where((topic) {
      final matchesQuery = query.isEmpty ||
          topic.category.title.toLowerCase().contains(query) ||
          topic.subtitle.toLowerCase().contains(query);
      final matchesDifficulty = filter.difficulty == null || topic.difficulty == filter.difficulty;
      return matchesQuery && matchesDifficulty;
    }).toList();
  }

  String _difficultyLabel(DiscoverDifficulty difficulty) {
    switch (difficulty) {
      case DiscoverDifficulty.easy:
        return 'Easy';
      case DiscoverDifficulty.medium:
        return 'Medium';
      case DiscoverDifficulty.hard:
        return 'Hard';
      case DiscoverDifficulty.expert:
        return 'Expert';
    }
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _DiscoverTopicCard extends StatelessWidget {
  const _DiscoverTopicCard({
    required this.topic,
    required this.completedThisWeek,
  });

  final DiscoverTopic topic;
  final bool completedThisWeek;

  @override
  Widget build(BuildContext context) {
    return BDCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.pushNamed(
        TriviaApp.nameGame,
        extra: {'categoryId': topic.category.id},
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                CategoryIconMapper.forCategory(topic.category),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                topic.category.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                topic.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  BDStatPill(label: 'Lvl', value: _difficultyText(topic.difficulty)),
                  BDStatPill(label: 'Packs', value: '${topic.packCount}'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: CategoryCompletionBadge(isCompleted: completedThisWeek),
          ),
        ],
      ),
    );
  }

  String _difficultyText(DiscoverDifficulty difficulty) {
    switch (difficulty) {
      case DiscoverDifficulty.easy:
        return 'Easy';
      case DiscoverDifficulty.medium:
        return 'Medium';
      case DiscoverDifficulty.hard:
        return 'Hard';
      case DiscoverDifficulty.expert:
        return 'Expert';
    }
  }
}
