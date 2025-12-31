import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/categories_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/bd_stat_pill.dart';
import '../widgets/category_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final textScale = MediaQuery.textScaleFactorOf(context);
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
