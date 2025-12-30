import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/brain_duel_theme.dart';

class InterstitialAdDialog extends StatefulWidget {
  const InterstitialAdDialog({super.key, this.duration = const Duration(seconds: 2)});

  final Duration duration;

  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(BrainDuelRadii.lg),
            gradient: const LinearGradient(
              colors: [Color(0xFF1D1A3A), Color(0xFF342D6B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sponsored',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                'Recharge your brain in 2 seconds',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Next: your challenge results',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
