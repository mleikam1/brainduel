class SoloPackLeaderboardEntry {
  final String uid;
  final int score;
  final int maxScore;
  final int? correct;
  final int? durationSeconds;
  final int rank;

  const SoloPackLeaderboardEntry({
    required this.uid,
    required this.score,
    required this.maxScore,
    required this.rank,
    this.correct,
    this.durationSeconds,
  });

  factory SoloPackLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return SoloPackLeaderboardEntry(
      uid: json['uid'] as String,
      score: (json['score'] as num).toInt(),
      maxScore: (json['maxScore'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      rank: (json['rank'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'score': score,
        'maxScore': maxScore,
        'correct': correct,
        'durationSeconds': durationSeconds,
        'rank': rank,
      };
}

class SoloPackLeaderboard {
  final List<SoloPackLeaderboardEntry> entries;
  final int userRank;

  const SoloPackLeaderboard({
    required this.entries,
    required this.userRank,
  });

  factory SoloPackLeaderboard.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    List<Map<String, dynamic>> entriesJson;
    if (rawEntries == null) {
      entriesJson = const [];
    } else if (rawEntries is List) {
      entriesJson = List<Map<String, dynamic>>.from(
        rawEntries.map((entry) {
          if (entry is! Map) {
            throw StateError('Invalid leaderboard entry payload.');
          }
          return Map<String, dynamic>.from(entry);
        }),
      );
    } else {
      throw StateError('Invalid leaderboard entries payload.');
    }
    return SoloPackLeaderboard(
      entries: entriesJson.map(SoloPackLeaderboardEntry.fromJson).toList(),
      userRank: (json['userRank'] as num?)?.toInt() ?? -1,
    );
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'userRank': userRank,
      };
}
