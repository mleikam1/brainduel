class TopicAccuracy {
  final String topicId;
  final String topicName;
  final double accuracy;
  final int totalQuestions;

  const TopicAccuracy({
    required this.topicId,
    required this.topicName,
    required this.accuracy,
    required this.totalQuestions,
  });
}

class ProfileBadge {
  final String title;
  final String description;
  final String icon;

  const ProfileBadge({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class ProfileInsights {
  final String displayName;
  final String rankTier;
  final int currentStreak;
  final int bestStreak;
  final int lifetimePoints;
  final int gamesPlayed;
  final int questionsAnswered;
  final double accuracy;
  final List<TopicAccuracy> topicAccuracies;
  final List<TopicAccuracy> bestTopics;
  final List<TopicAccuracy> weakestTopics;
  final List<ProfileBadge> badges;

  const ProfileInsights({
    required this.displayName,
    required this.rankTier,
    required this.currentStreak,
    required this.bestStreak,
    required this.lifetimePoints,
    required this.gamesPlayed,
    required this.questionsAnswered,
    required this.accuracy,
    required this.topicAccuracies,
    required this.bestTopics,
    required this.weakestTopics,
    required this.badges,
  });
}
