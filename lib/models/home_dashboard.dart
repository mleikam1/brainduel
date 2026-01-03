import 'category.dart';

class DailyChallengeSummary {
  final String id;
  final String title;
  final String subtitle;
  final int streak;
  final String timeRemaining;
  final int questionCount;
  final int points;

  const DailyChallengeSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.streak,
    required this.timeRemaining,
    required this.questionCount,
    required this.points,
  });
}

class HomePersonalizedRow {
  final String title;
  final List<Category> packs;

  const HomePersonalizedRow({
    required this.title,
    required this.packs,
  });
}

class HomeDashboard {
  final DailyChallengeSummary dailyChallenge;
  final List<Category> newAndUpdatedPacks;
  final List<HomePersonalizedRow> personalizedRows;

  const HomeDashboard({
    required this.dailyChallenge,
    required this.newAndUpdatedPacks,
    required this.personalizedRows,
  });
}
