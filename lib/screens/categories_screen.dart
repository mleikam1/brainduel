import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/categories_provider.dart';
import '../state/category_progress_provider.dart';
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
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(BrainDuelSpacing.sm),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search categories',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'No categories found.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: BrainDuelSpacing.sm),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = filtered[index];
                        final indicator = ref.watch(categoryWeeklyIndicatorProvider(category.id));
                        return CategoryCard(
                          category: category,
                          weeklyState: indicator.state,
                          showWeeklyRefresh: indicator.showWeeklyRefresh,
                          onTap: () {
                            context.pushNamed(
                              TriviaApp.nameCategoryDetail,
                              extra: category.id,
                            );
                          },
                        );
                      },
                      childCount: filtered.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
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
