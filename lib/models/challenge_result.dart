class ChallengeResult {
  final String attemptId;
  final String challengeId;
  final int points;
  final double percentile;
  final int rank;
  final int rankDelta;
  final Duration completionTime;
  final List<FriendRankEntry> friends;

  const ChallengeResult({
    required this.attemptId,
    required this.challengeId,
    required this.points,
    required this.percentile,
    required this.rank,
    required this.rankDelta,
    required this.completionTime,
    required this.friends,
  });
}

class FriendRankEntry {
  final String name;
  final int points;
  final int rank;
  final int delta;

  const FriendRankEntry({
    required this.name,
    required this.points,
    required this.rank,
    required this.delta,
  });
}
