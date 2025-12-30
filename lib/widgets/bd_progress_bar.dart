import 'package:flutter/material.dart';
import '../theme/brain_duel_theme.dart';

class BDProgressBar extends StatelessWidget {
  const BDProgressBar({
    super.key,
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(BrainDuelRadii.sm),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: BrainDuelColors.fog,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
