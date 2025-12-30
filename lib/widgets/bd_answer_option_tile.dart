import 'package:flutter/material.dart';
import '../theme/brain_duel_theme.dart';

enum BDAnswerState {
  idle,
  selected,
  correct,
  incorrect,
  disabled,
}

class BDAnswerOptionTile extends StatelessWidget {
  const BDAnswerOptionTile({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final BDAnswerState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color borderColor = BrainDuelColors.fog;
    Color background = Colors.white;
    Color textColor = colors.onSurface;
    IconData? trailingIcon;

    switch (state) {
      case BDAnswerState.selected:
        borderColor = colors.primary;
        background = colors.primary.withOpacity(0.08);
        break;
      case BDAnswerState.correct:
        borderColor = Colors.green;
        background = Colors.green.withOpacity(0.12);
        trailingIcon = Icons.check_circle;
        break;
      case BDAnswerState.incorrect:
        borderColor = BrainDuelColors.rose;
        background = BrainDuelColors.rose.withOpacity(0.12);
        trailingIcon = Icons.cancel;
        break;
      case BDAnswerState.disabled:
        borderColor = BrainDuelColors.fog;
        background = BrainDuelColors.fog.withOpacity(0.4);
        textColor = colors.onSurface.withOpacity(0.6);
        break;
      case BDAnswerState.idle:
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(BrainDuelRadii.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(BrainDuelRadii.md),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: borderColor),
          ],
        ),
      ),
    );
  }
}
