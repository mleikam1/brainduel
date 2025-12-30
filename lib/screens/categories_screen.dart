import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/categories_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/category_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncCats = ref.watch(categoriesProvider);

    return BDAppScaffold(
      title: 'Categories',
      subtitle: 'Choose your battleground',
      child: asyncCats.when(
        data: (cats) {
          final filtered = cats.where((c) => c.title.toLowerCase().contains(_query.toLowerCase())).toList();
          return LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final columnCount = (constraints.maxWidth / 220).floor().clamp(1, 3).toInt();
              final totalSpacing = spacing * (columnCount - 1);
              final cardWidth = (constraints.maxWidth - totalSpacing) / columnCount;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(BrainDuelSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search categories',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const Center(
                        child: Text(
                          'No categories found.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: filtered.map((c) {
                          final detail = ref.read(categoryDetailProvider(c));
                          return SizedBox(
                            width: cardWidth,
                            child: CategoryCard(
                              category: c,
                              subtitle: detail.subtitle,
                              points: detail.points,
                              questionCount: detail.questionCount,
                              onTap: () {
                                context.pushNamed(
                                  TriviaApp.nameCategoryDetail,
                                  extra: c.id,
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load categories: $e',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.refresh(categoriesProvider),
                child: const Text(
                  'Retry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
