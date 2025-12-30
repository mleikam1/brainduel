import '../models/home_challenge.dart';
import '../models/home_feed.dart';
import '../models/seasonal_event.dart';

class HomeFeedService {
  Future<HomeFeed> fetchHomeFeed() async {
    const dailyChallenges = [
      HomeChallenge(
        id: 'daily_global_01',
        title: 'Daily Duel: World Wonders',
        subtitle: 'Classic landmarks and legends',
        badge: 'Daily',
        timeRemaining: 'Ends in 6h',
        questionCount: 12,
        points: 800,
      ),
      HomeChallenge(
        id: 'daily_speed_02',
        title: 'Quickfire Cosmos',
        subtitle: 'Beat the clock on space trivia',
        badge: 'Speed',
        timeRemaining: 'Ends in 10h',
        questionCount: 10,
        points: 750,
      ),
    ];

    const trendingChallenges = [
      HomeChallenge(
        id: 'public_tech_14',
        title: 'Tech Titans Throwdown',
        subtitle: 'Silicon Valley, startups, and gadgets',
        badge: 'Public',
        timeRemaining: 'Open now',
        questionCount: 15,
        points: 1200,
      ),
      HomeChallenge(
        id: 'public_sports_11',
        title: 'Championship Sprint',
        subtitle: 'High-stakes sports moments',
        badge: 'Public',
        timeRemaining: 'Open now',
        questionCount: 16,
        points: 1250,
      ),
      HomeChallenge(
        id: 'public_pop_09',
        title: 'Pop Culture Pulse',
        subtitle: 'Shows, music, and viral trends',
        badge: 'Public',
        timeRemaining: 'Open now',
        questionCount: 14,
        points: 1100,
      ),
    ];

    const seasonalEvent = SeasonalEvent(
      id: 'season_emberfall',
      title: 'Emberfall Cup',
      description: 'Rack up points this week for exclusive rewards and a limited leaderboard.',
      rewardLabel: 'Season bonus +300',
      timeRemaining: '4 days left',
    );

    return const HomeFeed(
      dailyChallenges: dailyChallenges,
      trendingChallenges: trendingChallenges,
      seasonalEvent: seasonalEvent,
    );
  }
}
