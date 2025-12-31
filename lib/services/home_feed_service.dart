import '../models/home_challenge.dart';
import '../models/home_feed.dart';
import '../models/seasonal_event.dart';

class HomeFeedService {
  Future<HomeFeed> fetchHomeFeed() async {
    const seasonalEventChallenges = [
      HomeChallenge(
        id: 'event_emberfall_01',
        title: 'Molten Minds',
        subtitle: 'Fire myths, volcanoes, and heat waves',
        badge: 'Event',
        timeRemaining: 'Ends in 4d',
        questionCount: 14,
        points: 1400,
      ),
      HomeChallenge(
        id: 'event_emberfall_02',
        title: 'Ashfall Archives',
        subtitle: 'Ancient ruins and legendary discoveries',
        badge: 'Event',
        timeRemaining: 'Ends in 4d',
        questionCount: 12,
        points: 1300,
      ),
      HomeChallenge(
        id: 'event_emberfall_03',
        title: 'Forge Fighters',
        subtitle: 'Battles, warriors, and epic duels',
        badge: 'Event',
        timeRemaining: 'Ends in 4d',
        questionCount: 15,
        points: 1500,
      ),
    ];

    const seasonalEvent = SeasonalEvent(
      id: 'season_emberfall',
      title: 'Emberfall Cup',
      description: 'Rack up points this week for exclusive rewards and a limited leaderboard.',
      rewardLabel: 'Season bonus +300',
      timeRemaining: '4 days left',
      challenges: seasonalEventChallenges,
    );

    return const HomeFeed(
      seasonalEvent: seasonalEvent,
    );
  }
}
