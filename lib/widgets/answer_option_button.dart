import 'package:flutter/material.dart';

class AnswerOptionButton extends StatelessWidget {
  const AnswerOptionButton({
    super.key,
    required this.text,
    required this.disabled,
    required this.isSelected,
    required this.showCorrectness,
    required this.isCorrectAnswer,
    required this.onTap,
  });

  final String text;
  final bool disabled;
  final bool isSelected;
  final bool showCorrectness;
  final bool isCorrectAnswer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? border;
    Color? bg;

    if (showCorrectness) {
      if (isCorrectAnswer) {
        border = Colors.green;
        bg = Colors.green.withOpacity(0.10);
      } else if (isSelected && !isCorrectAnswer) {
        border = Colors.red;
        bg = Colors.red.withOpacity(0.10);
      }
    } else if (isSelected) {
      border = Theme.of(context).colorScheme.primary;
      bg = Theme.of(context).colorScheme.primary.withOpacity(0.08);
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border ?? Colors.black12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
