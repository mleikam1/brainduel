import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/brain_duel_theme.dart';
import '../utils/category_icon_mapper.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
        ),
      ),
    );
  }
}
