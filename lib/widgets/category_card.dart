import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/brain_duel_theme.dart';
import 'bd_card.dart';
import 'bd_stat_pill.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.subtitle,
    required this.points,
    required this.questionCount,
    required this.onTap,
  });

  final Category category;
  final String subtitle;
  final int points;
  final int questionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BDCard(
      onTap: onTap,
      // Overflow-safe card layout: shrink-wrap the column and wrap badges so
      // the card grows vertically with content in grids/lists.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: BrainDuelColors.glacier.withOpacity(0.12),
                  borderRadius: const BorderRadius.all(BrainDuelRadii.sm),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BDStatPill(label: 'Qs', value: '$questionCount'),
              BDStatPill(label: 'Pts', value: '$points'),
            ],
          ),
        ],
      ),
    );
  }
}
