import 'package:flutter/material.dart';
import '../app.dart';
import '../models/leaderboard_entry.dart';
import '../theme/brain_duel_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bd_avatar.dart';
import '../widgets/bd_buttons.dart';
import '../widgets/bd_card.dart';
import '../widgets/score_summary.dart';

class TriviaResultScreen extends StatelessWidget {
  const TriviaResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
    final categoryId = (args['categoryId'] as String?) ?? 'sports';
    final correct = (args['correct'] as int?) ?? 0;
    final total = (args['total'] as int?) ?? 0;
    final startedAt = DateTime.tryParse(args['startedAt'] as String? ?? '');
    final timeTaken = startedAt == null ? const Duration(seconds: 0) : DateTime.now().difference(startedAt);
    final points = correct * 100;

    final participants = [
      LeaderboardEntry(name: 'You', points: points, time: timeTaken, rank: 2),
      const LeaderboardEntry(name: 'Renata M.', points: 1840, time: Duration(minutes: 1, seconds: 12), rank: 1),
      const LeaderboardEntry(name: 'Mike S.', points: 1650, time: Duration(minutes: 1, seconds: 26), rank: 3),
      const LeaderboardEntry(name: 'John M.', points: 1240, time: Duration(minutes: 1, seconds: 45), rank: 4),
      const LeaderboardEntry(name: 'Dinny K.', points: 1180, time: Duration(minutes: 1, seconds: 54), rank: 5),
    ]..sort((a, b) => a.rank.compareTo(b.rank));

    return BDAppScaffold(
      title: 'Scoreboard',
      child: Padding(
        padding: const EdgeInsets.all(BrainDuelSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScoreSummary(correct: correct, total: total, points: points, timeTaken: timeTaken),
            const SizedBox(height: 16),
            Text('Top Rankings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: participants.take(3).map((entry) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: BDCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          BDAvatar(name: entry.name, radius: 18),
                          const SizedBox(height: 8),
                          Text(
                            '#${entry.rank}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(entry.name, style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text('${entry.points} pts', style: Theme.of(context).textTheme.labelLarge),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: participants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = participants[index];
                  final minutes = entry.time.inMinutes;
                  final seconds = entry.time.inSeconds.remainder(60);
                  return BDCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Text('#${entry.rank}', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(width: 12),
                        BDAvatar(name: entry.name, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.name, style: Theme.of(context).textTheme.bodyLarge)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${entry.points} pts', style: Theme.of(context).textTheme.bodyLarge),
                            Text('${minutes}m ${seconds}s', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            BDPrimaryButton(
              label: 'Share Results',
              icon: Icons.share,
              isExpanded: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share hook ready for integration.')),
                );
              },
            ),
            const SizedBox(height: 10),
            BDSecondaryButton(
              label: 'Play Again',
              isExpanded: true,
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                TriviaApp.routeGame,
                arguments: categoryId,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                TriviaApp.routeCategories,
                    (route) => route.settings.name == TriviaApp.routeHome,
              ),
              child: const Text('Back to Categories'),
            ),
          ],
        ),
      ),
    );
  }
}
