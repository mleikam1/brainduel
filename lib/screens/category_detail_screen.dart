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

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = ModalRoute.of(context)?.settings.arguments as String?;
    final categoriesAsync = ref.watch(categoriesProvider);

    return BDAppScaffold(
      title: 'Category',
      child: categoriesAsync.when(
        data: (categories) {
          final category = categories.firstWhere(
                (c) => c.id == categoryId,
            orElse: () => categories.first,
          );
          final detail = ref.read(categoryDetailProvider(category));
          final rankings = ref.read(categoryRankingsProvider(category.id));

          return ListView(
            padding: const EdgeInsets.all(BrainDuelSpacing.sm),
            children: [
              BDCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(category.icon, style: const TextStyle(fontSize: 48)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(category.title, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(detail.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        BDStatPill(label: 'Pts', value: '${detail.points}'),
                        BDStatPill(label: 'Quizzes', value: '${detail.packCount}'),
                        BDStatPill(label: 'Qs', value: '${detail.questionCount}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(detail.description),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Top Rankings', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Column(
                children: rankings.map((entry) {
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
                          Text('${entry.points} pts', style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              BDPrimaryButton(
                label: 'Play Solo',
                isExpanded: true,
                onPressed: () => context.pushNamed(
                  TriviaApp.nameGame,
                  extra: category.id,
                ),
              ),
              const SizedBox(height: 10),
              BDSecondaryButton(
                label: 'Play with Friends',
                isExpanded: true,
                onPressed: null,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}
