import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BDAppScaffold(
      title: 'Welcome',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Brain Duel',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Sharpen your knowledge and challenge friends in quick, fair trivia battles.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            BDPrimaryButton(
              label: 'Get Started',
              isExpanded: true,
              onPressed: () => context.goNamed(TriviaApp.nameTopicSelect),
            ),
          ],
        ),
      ),
    );
  }
}
