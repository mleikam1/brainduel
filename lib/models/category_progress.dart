class CategoryProgress {
  final String weekKey;
  final int cursor;
  final int exhaustedCount;

  const CategoryProgress({
    required this.weekKey,
    required this.cursor,
    required this.exhaustedCount,
  });

  factory CategoryProgress.fromJson(Map<String, dynamic> json) {
    return CategoryProgress(
      weekKey: (json['weekKey'] as String?) ?? '',
      cursor: (json['cursor'] as num?)?.toInt() ?? 0,
      exhaustedCount: (json['exhaustedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
