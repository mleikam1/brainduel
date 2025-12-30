import 'package:flutter/material.dart';
import '../theme/brain_duel_theme.dart';

class BDAvatar extends StatelessWidget {
  const BDAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.background,
  });

  final String name;
  final double radius;
  final Color? background;

  String get initials {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? BrainDuelColors.glacier.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: background == null ? BrainDuelColors.midnight : Colors.white,
        ),
      ),
    );
  }
}
