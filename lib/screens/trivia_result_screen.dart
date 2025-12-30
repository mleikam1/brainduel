import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/score_summary.dart';

class TriviaResultScreen extends StatelessWidget {
  const TriviaResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final categoryId = (args['categoryId'] as String?) ?? 'sports';
    final correct = (args['correct'] as int?) ?? 0;
    final total = (args['total'] as int?) ?? 0;

    return AppScaffold(
      title: 'Results',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ScoreSummary(correct: correct, total: total),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                TriviaApp.routeGame,
                arguments: categoryId,
              ),
              child: const Text('Play Again'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                TriviaApp.routeCategories,
                    (route) => route.settings.name == TriviaApp.routeHome,
              ),
              child: const Text('Choose Another Category'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                TriviaApp.routeHome,
                    (_) => false,
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
