import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/category.dart';
import '../state/categories_provider.dart';
import '../state/topic_selection_provider.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';

class TopicSelectScreen extends ConsumerWidget {
  const TopicSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selections = ref.watch(topicSelectionProvider);

    return BDAppScaffold(
      title: 'Pick Topics',
      subtitle: 'Choose at least 3 topics to personalize your battles',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: categories.when(
          data: (cats) {
            return selections.when(
              data: (selected) => _TopicSelectionContent(
                categories: cats,
                selected: selected,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Failed to load selections: $error'),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load topics: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.refresh(categoriesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicSelectionContent extends ConsumerWidget {
  const _TopicSelectionContent({
    required this.categories,
    required this.selected,
  });

  final List<Category> categories;
  final Set<String> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = 3 - selected.length;
    final canContinue = selected.length >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          canContinue
              ? 'Great picks! You can continue.'
              : 'Pick ${remaining} more topic${remaining == 1 ? '' : 's'} to continue.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              final detail = ref.read(categoryDetailProvider(category));
              return CheckboxListTile(
                value: selected.contains(category.id),
                title: Text(category.title),
                subtitle: Text(detail.subtitle),
                onChanged: (_) => ref.read(topicSelectionProvider.notifier).toggleTopic(category.id),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        BDPrimaryButton(
          label: 'Continue',
          isExpanded: true,
          onPressed: canContinue
              ? () async {
                  final success =
                      await ref.read(topicSelectionProvider.notifier).completeSelection();
                  if (success && context.mounted) {
                    context.goNamed(TriviaApp.nameHome);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
