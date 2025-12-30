import 'package:flutter/material.dart';
import '../theme/brain_duel_theme.dart';

class BDCard extends StatelessWidget {
  const BDCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(BrainDuelRadii.md),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
