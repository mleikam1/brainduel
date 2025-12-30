class RecentGame {
  final String categoryId;
  final DateTime playedAt;
  final int correct;
  final int total;

  const RecentGame({
    required this.categoryId,
    required this.playedAt,
    required this.correct,
    required this.total,
  });
}
