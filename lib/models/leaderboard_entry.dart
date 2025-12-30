class LeaderboardEntry {
  final String name;
  final int points;
  final Duration time;
  final int rank;

  const LeaderboardEntry({
    required this.name,
    required this.points,
    required this.time,
    required this.rank,
  });
}
