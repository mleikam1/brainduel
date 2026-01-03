import '../models/category.dart';
import '../models/profile_insights.dart';
import '../state/user_stats_provider.dart';

class ProfileInsightsService {
  ProfileInsights buildInsights({
    required UserStats stats,
    required List<Category> categories,
  }) {
    final topicAccuracies = _buildTopicAccuracies(stats, categories);
    final sorted = [...topicAccuracies]..sort((a, b) => b.accuracy.compareTo(a.accuracy));
    final best = sorted.take(2).toList();
    final weakest = sorted.reversed.take(2).toList();

    return ProfileInsights(
      displayName: 'Matt Leikam',
      rankTier: 'Gold II',
      // Assumption: current streak is derived from the best streak in local stats until streak history is persisted.
      currentStreak: stats.bestStreak == 0 ? 0 : (stats.bestStreak - 1).clamp(0, stats.bestStreak),
      bestStreak: stats.bestStreak,
      lifetimePoints: stats.totalPoints,
      gamesPlayed: stats.gamesPlayed,
      questionsAnswered: stats.questionsAnswered,
      accuracy: stats.accuracy,
      topicAccuracies: topicAccuracies,
      bestTopics: best,
      weakestTopics: weakest,
      badges: _badges(stats),
    );
  }

  List<TopicAccuracy> _buildTopicAccuracies(UserStats stats, List<Category> categories) {
    final totals = <String, int>{};
    final correct = <String, int>{};

    for (final game in stats.recentGames) {
      totals.update(game.categoryId, (value) => value + game.total, ifAbsent: () => game.total);
      correct.update(game.categoryId, (value) => value + game.correct, ifAbsent: () => game.correct);
    }

    if (categories.isEmpty) return const [];

    return categories.map((category) {
      final total = totals[category.id] ?? 0;
      final correctCount = correct[category.id] ?? 0;
      final accuracy = total == 0 ? 0.0 : correctCount / total;
      return TopicAccuracy(
        topicId: category.id,
        topicName: category.title,
        accuracy: accuracy,
        totalQuestions: total,
      );
    }).toList();
  }

  List<ProfileBadge> _badges(UserStats stats) {
    return [
      ProfileBadge(
        title: 'Fast Starter',
        description: 'Win your first duel',
        icon: '⚡️',
      ),
      ProfileBadge(
        title: 'Combo Builder',
        description: 'Answer 10 in a row',
        icon: '🔥',
      ),
      ProfileBadge(
        title: 'Arena Regular',
        description: 'Play ${stats.gamesPlayed} matches',
        icon: '🏆',
      ),
    ];
  }
}
