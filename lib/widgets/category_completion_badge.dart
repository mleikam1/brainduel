import 'package:flutter/material.dart';

class CategoryCompletionBadge extends StatelessWidget {
  const CategoryCompletionBadge({
    super.key,
    required this.isCompleted,
    this.label = 'Completed',
    this.icon = Icons.check_circle,
  });

  final bool isCompleted;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (!isCompleted) {
      return const SizedBox.shrink();
    }
    final tone = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: tone),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tone),
            ),
          ],
        ),
      ),
    );
  }
}
