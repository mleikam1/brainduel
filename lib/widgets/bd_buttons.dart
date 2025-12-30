import 'package:flutter/material.dart';

class BDPrimaryButton extends StatelessWidget {
  const BDPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    final button = FilledButton(
      onPressed: onPressed,
      child: child,
    );

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class BDSecondaryButton extends StatelessWidget {
  const BDSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    final button = OutlinedButton(
      onPressed: onPressed,
      child: child,
    );

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
