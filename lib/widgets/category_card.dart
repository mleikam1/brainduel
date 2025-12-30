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
      // RenderFlex overflow diagnosis: a Spacer inside a grid-constrained card
      // forced stat pills below the visible bounds. Fix by shrink-wrapping the
      // column and letting pills wrap within available space.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: BrainDuelColors.glacier.withOpacity(0.12),
              borderRadius: const BorderRadius.all(BrainDuelRadii.sm),
            ),
            child: Center(
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
