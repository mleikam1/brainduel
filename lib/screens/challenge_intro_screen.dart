import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_buttons.dart';

class ChallengeIntroScreen extends StatelessWidget {
  const ChallengeIntroScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return BDAppScaffold(
      title: 'Challenge Ready',
      subtitle: 'Code $challengeId',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You have been invited to a Brain Duel.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'This attempt is locked to a single run for fairness. Ready to begin?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            BDPrimaryButton(
              label: 'Start Challenge',
              isExpanded: true,
              onPressed: () => context.goNamed(
                TriviaApp.nameQuestionFlow,
                pathParameters: {'challengeId': challengeId},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
