import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/category_weekly_indicator.dart';
import '../theme/brain_duel_theme.dart';
import '../utils/category_icon_mapper.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.weeklyState,
    this.showWeeklyRefresh = false,
  });

  final Category category;
  final VoidCallback onTap;
  final CategoryWeeklyState? weeklyState;
  final bool showWeeklyRefresh;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (weeklyState) {
      CategoryWeeklyState.fresh => 'Fresh this week',
      CategoryWeeklyState.completed => 'Completed this week',
      _ => null,
    };
    final statusTone = switch (weeklyState) {
      CategoryWeeklyState.fresh => Theme.of(context).colorScheme.tertiary,
      CategoryWeeklyState.completed => Theme.of(context).colorScheme.primary,
      _ => Theme.of(context).colorScheme.primary,
    };
    final showStatus = statusLabel != null || showWeeklyRefresh;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(BrainDuelRadii.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(BrainDuelRadii.md),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: BrainDuelColors.glacier.withOpacity(0.12),
                  borderRadius: const BorderRadius.all(BrainDuelRadii.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    CategoryIconMapper.forCategory(category),
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                category.title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (showStatus) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    if (statusLabel != null)
                      _CategoryStatusPill(
                        label: statusLabel,
                        tone: statusTone,
                      ),
                    if (showWeeklyRefresh)
                      _CategoryStatusPill(
                        label: 'Weekly refresh',
                        tone: Theme.of(context).colorScheme.secondary,
                        icon: Icons.refresh,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStatusPill extends StatelessWidget {
  const _CategoryStatusPill({
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final Color tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: tone),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tone),
            ),
          ],
        ),
      ),
    );
  }
}
