import 'home_challenge.dart';
import 'seasonal_event.dart';

class HomeFeed {
  final List<HomeChallenge> dailyChallenges;
  final List<HomeChallenge> trendingChallenges;
  final SeasonalEvent? seasonalEvent;

  const HomeFeed({
    required this.dailyChallenges,
    required this.trendingChallenges,
    this.seasonalEvent,
  });
}
