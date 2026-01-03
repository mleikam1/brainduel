import 'dart:math';
import '../models/category.dart';
import '../models/home_dashboard.dart';
import '../services/challenge_service.dart';
import '../services/storage_content_service.dart';

class HomeDashboardService {
  HomeDashboardService({
    required this.challengeService,
    required this.storage,
  });

  final ChallengeService challengeService;
  final StorageContentService storage;

  Future<HomeDashboard> buildDashboard({
    required List<Category> categories,
    required Set<String> selectedTopicIds,
  }) async {
    final challengeIds = storage.listChallengeIds();
    final dailyChallengeId = _pickDailyChallengeId(challengeIds);
    final definition = await challengeService.fetchDefinition(dailyChallengeId);
    final metadata = definition.metadata;
    final dailyChallenge = DailyChallengeSummary(
      id: dailyChallengeId,
      title: metadata.title,
      subtitle: '${metadata.topic} • ${metadata.difficulty}',
      // Assumption: until backend streak tracking exists, derive a repeatable streak from the day of month.
      streak: (DateTime.now().day % 6) + 1,
      timeRemaining: _dailyWindowRemaining(),
      questionCount: definition.questions.length,
      points: 1200,
    );

    final newAndUpdated = _selectNewAndUpdated(categories);
    final personalized = _buildPersonalizedRows(categories, selectedTopicIds);

    return HomeDashboard(
      dailyChallenge: dailyChallenge,
      newAndUpdatedPacks: newAndUpdated,
      personalizedRows: personalized,
    );
  }

  String _pickDailyChallengeId(List<String> challengeIds) {
    if (challengeIds.isEmpty) {
      return 'featured_global_01';
    }
    final now = DateTime.now().toUtc();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return challengeIds[seed % challengeIds.length];
  }

  String _dailyWindowRemaining() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrow.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours}h ${minutes}m left';
  }

  List<Category> _selectNewAndUpdated(List<Category> categories) {
    if (categories.isEmpty) return const [];
    // Assumption: highlight two rotating packs daily since we do not yet track real update timestamps.
    final shuffled = _seededShuffle(categories, DateTime.now().day);
    return shuffled.take(min(4, shuffled.length)).toList();
  }

  List<HomePersonalizedRow> _buildPersonalizedRows(
    List<Category> categories,
    Set<String> selectedTopicIds,
  ) {
    if (categories.isEmpty) return const [];
    final selection = selectedTopicIds.isEmpty
        ? categories.take(min(2, categories.length)).map((c) => c.id).toSet()
        : selectedTopicIds;

    return selection.map((topicId) {
      final topic = categories.firstWhere(
        (category) => category.id == topicId,
        orElse: () => categories.first,
      );
      final related = _seededShuffle(categories, topicId.hashCode)
          .where((category) => category.id != topic.id)
          .take(min(3, categories.length))
          .toList();
      return HomePersonalizedRow(
        title: 'Because you like ${topic.title}',
        packs: [topic, ...related],
      );
    }).toList();
  }

  List<Category> _seededShuffle(List<Category> categories, int seed) {
    final rng = Random(seed);
    final list = [...categories];
    list.shuffle(rng);
    return list;
  }
}
