import 'package:flutter/material.dart';
import '../app.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Home',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Quick trivia, minimal backend.\nPerfect MVP starter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(TriviaApp.routeCategories),
              child: const Text('Browse Categories'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed(TriviaApp.routeProfile),
              child: const Text('View Profile / Stats'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(TriviaApp.routeSettings),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
