import 'leaderboard_entry.dart';

enum RankingsPeriod { weekly, monthly }

enum RankingsScope { global, friends, topic }

class RankProgress {
  final String tier;
  final String nextTier;
  final int currentPoints;
  final int nextTierPoints;

  const RankProgress({
    required this.tier,
    required this.nextTier,
    required this.currentPoints,
    required this.nextTierPoints,
  });

  double get progress => nextTierPoints == 0 ? 0 : currentPoints / nextTierPoints;
}

class WinLossRecord {
  final String opponent;
  final bool win;
  final String modeLabel;
  final String scoreLine;
  final String timeLabel;

  const WinLossRecord({
    required this.opponent,
    required this.win,
    required this.modeLabel,
    required this.scoreLine,
    required this.timeLabel,
  });
}

class RankingsContent {
  final RankProgress rankProgress;
  final List<LeaderboardEntry> globalLeaderboard;
  final List<LeaderboardEntry> friendsLeaderboard;
  final Map<String, List<LeaderboardEntry>> topicLeaderboards;
  final List<WinLossRecord> duelHistory;

  const RankingsContent({
    required this.rankProgress,
    required this.globalLeaderboard,
    required this.friendsLeaderboard,
    required this.topicLeaderboards,
    required this.duelHistory,
  });
}
