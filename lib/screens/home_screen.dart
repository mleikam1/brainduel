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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return BDAppScaffold(
      title: 'Brain Duel',
      subtitle: 'Competitive trivia arena',
      actions: [
        IconButton(
          onPressed: () => context.pushNamed(TriviaApp.nameProfile),
          icon: const BDAvatar(name: 'Alex', radius: 18),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        children: [
          BDCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back, Alex', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Ranked streak: 4 wins',
                  style: Theme.of(context).textTheme.bodyMedium,
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
          const SizedBox(height: 16),
          Row(
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
                  onPressed: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Trending Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
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
                      width: 180,
                      child: BDCard(
                        onTap: () => context.pushNamed(
                          TriviaApp.nameCategoryDetail,
                          extra: category.id,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.icon, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 10),
                            Text(category.title, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(detail.subtitle, style: Theme.of(context).textTheme.bodySmall),
                            const Spacer(),
                            BDStatPill(label: 'Pts', value: '${detail.points}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Failed to load: $error')),
            ),
          ),
          const SizedBox(height: 20),
          Text('Your Recent Packs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) {
              final recent = categories.take(3).toList();
              return Column(
                children: recent.map((category) {
                  final detail = ref.read(categoryDetailProvider(category));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BDCard(
                      onTap: () => context.pushNamed(
                        TriviaApp.nameCategoryDetail,
                        extra: category.id,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(category.icon, style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category.title, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text('${detail.questionCount} questions • ${detail.points} pts'),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Failed to load: $error')),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.pushNamed(TriviaApp.nameSettings),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}
