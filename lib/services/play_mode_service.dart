import '../models/play_mode.dart';
import 'storage_content_service.dart';

class PlayModeService {
  PlayModeService({required this.storage});

  final StorageContentService storage;

  List<PlayMode> fetchModes() {
    final challengeIds = storage.listChallengeIds();
    final speedChallenge = _pickByKeyword(challengeIds, 'speed');
    final globalChallenge = _pickByKeyword(challengeIds, 'global');
    final techChallenge = _pickByKeyword(challengeIds, 'tech');
    final sportsChallenge = _pickByKeyword(challengeIds, 'sports');

    return [
      PlayMode(
        id: 'solo_timed',
        title: 'Solo Timed Run',
        description: 'Race the clock for maximum points and accuracy.',
        riskLabel: 'Fast timers',
        rewardLabel: 'Combo multipliers',
        ctaLabel: 'Start Run',
        ranked: false,
        destination: const PlayDestination.categories(),
      ),
      PlayMode(
        id: 'async_duel',
        title: 'Head-to-Head Async Duel',
        description: 'Fire the first shot and let friends answer on their time.',
        riskLabel: 'One attempt',
        rewardLabel: 'Duel streaks',
        ctaLabel: 'Send Challenge',
        ranked: true,
        destination: PlayDestination.challenge(globalChallenge),
      ),
      PlayMode(
        id: 'sudden_death',
        title: 'Sudden Death',
        description: 'One miss and you are out — pure clutch pressure.',
        riskLabel: 'Instant elimination',
        rewardLabel: 'High XP',
        ctaLabel: 'Enter Arena',
        ranked: false,
        destination: PlayDestination.challenge(sportsChallenge),
      ),
      PlayMode(
        id: 'speed_round',
        title: 'Speed Round',
        description: 'Short bursts, lightning answers, no pauses.',
        riskLabel: 'No retries',
        rewardLabel: 'Speed bonus',
        ctaLabel: 'Go Fast',
        ranked: false,
        destination: PlayDestination.challenge(speedChallenge),
      ),
      PlayMode(
        id: 'hardcore',
        title: 'Hardcore',
        description: 'No lifelines. Only mastery and memory.',
        riskLabel: 'No hints',
        rewardLabel: 'Elite badge',
        ctaLabel: 'Lock In',
        ranked: false,
        destination: PlayDestination.challenge(techChallenge),
      ),
      PlayMode(
        id: 'prove_it',
        title: 'Prove It',
        description: 'High difficulty, ranked stakes, and real bragging rights.',
        riskLabel: 'Ranked loss',
        rewardLabel: 'Tier climbs',
        ctaLabel: 'Prove It',
        ranked: true,
        destination: PlayDestination.challenge(speedChallenge),
      ),
    ];
  }

  String _pickByKeyword(List<String> challengeIds, String keyword) {
    if (challengeIds.isEmpty) return 'featured_global_01';
    final match = challengeIds.firstWhere(
      (id) => id.contains(keyword),
      orElse: () => challengeIds.first,
    );
    return match;
  }
}
