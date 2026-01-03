import '../models/category.dart';
import '../models/leaderboard_entry.dart';
import '../models/rankings_content.dart';

class RankingsService {
  RankingsContent buildRankings({
    required RankingsPeriod period,
    required List<Category> categories,
  }) {
    final global = _globalLeaderboard(period);
    final friends = _friendsLeaderboard(period);
    final topics = <String, List<LeaderboardEntry>>{};
    if (categories.isEmpty) {
      topics['general'] = _topicLeaderboard('General', period);
    } else {
      for (final category in categories) {
        topics[category.id] = _topicLeaderboard(category.title, period);
      }
    }

    return RankingsContent(
      rankProgress: RankProgress(
        tier: 'Gold II',
        nextTier: 'Platinum I',
        currentPoints: period == RankingsPeriod.weekly ? 1420 : 5680,
        nextTierPoints: period == RankingsPeriod.weekly ? 1800 : 6400,
      ),
      globalLeaderboard: global,
      friendsLeaderboard: friends,
      topicLeaderboards: topics,
      duelHistory: _duelHistory(period),
    );
  }

  List<LeaderboardEntry> _globalLeaderboard(RankingsPeriod period) {
    final base = period == RankingsPeriod.weekly ? 1700 : 9800;
    return [
      LeaderboardEntry(name: 'Renata M.', points: base + 420, time: const Duration(minutes: 1), rank: 1),
      LeaderboardEntry(name: 'You', points: base + 180, time: const Duration(minutes: 1, seconds: 12), rank: 2),
      LeaderboardEntry(name: 'Mike S.', points: base + 80, time: const Duration(minutes: 1, seconds: 20), rank: 3),
      LeaderboardEntry(name: 'Dinny K.', points: base - 40, time: const Duration(minutes: 1, seconds: 34), rank: 4),
      LeaderboardEntry(name: 'Jordan L.', points: base - 120, time: const Duration(minutes: 1, seconds: 42), rank: 5),
    ];
  }

  List<LeaderboardEntry> _friendsLeaderboard(RankingsPeriod period) {
    final base = period == RankingsPeriod.weekly ? 1180 : 4300;
    return [
      LeaderboardEntry(name: 'You', points: base + 120, time: const Duration(minutes: 1, seconds: 8), rank: 1),
      LeaderboardEntry(name: 'Alex V.', points: base + 40, time: const Duration(minutes: 1, seconds: 18), rank: 2),
      LeaderboardEntry(name: 'Jae P.', points: base - 30, time: const Duration(minutes: 1, seconds: 25), rank: 3),
      LeaderboardEntry(name: 'Nina C.', points: base - 80, time: const Duration(minutes: 1, seconds: 38), rank: 4),
    ];
  }

  List<LeaderboardEntry> _topicLeaderboard(String topic, RankingsPeriod period) {
    final base = period == RankingsPeriod.weekly ? 1500 : 5100;
    return [
      LeaderboardEntry(name: '$topic Ace', points: base + 260, time: const Duration(minutes: 1, seconds: 6), rank: 1),
      LeaderboardEntry(name: 'You', points: base + 120, time: const Duration(minutes: 1, seconds: 14), rank: 2),
      LeaderboardEntry(name: '$topic Pro', points: base + 40, time: const Duration(minutes: 1, seconds: 22), rank: 3),
    ];
  }

  List<WinLossRecord> _duelHistory(RankingsPeriod period) {
    // Assumption: duel outcomes are mocked locally until match history is stored server-side.
    return [
      const WinLossRecord(
        opponent: 'Renata M.',
        win: true,
        modeLabel: 'Async Duel',
        scoreLine: '12–9',
        timeLabel: '2h ago',
      ),
      const WinLossRecord(
        opponent: 'Mike S.',
        win: false,
        modeLabel: 'Sudden Death',
        scoreLine: '7–8',
        timeLabel: 'Yesterday',
      ),
      const WinLossRecord(
        opponent: 'Alex V.',
        win: true,
        modeLabel: 'Speed Round',
        scoreLine: '15–12',
        timeLabel: period == RankingsPeriod.weekly ? '3d ago' : '2w ago',
      ),
    ];
  }
}
