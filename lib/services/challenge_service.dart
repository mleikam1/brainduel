import 'dart:convert';
import 'dart:math';
import '../models/challenge.dart';
import '../models/challenge_answer_record.dart';
import '../models/challenge_result.dart';
import '../models/rematch.dart';
import 'content_cache_service.dart';
import 'storage_content_service.dart';

class ChallengeService {
  ChallengeService({
    required this.storage,
    required this.cache,
  });

  final StorageContentService storage;
  final ContentCacheService cache;

  Future<ChallengeMetadata> fetchMetadata(String challengeId) async {
    final definition = await _fetchDefinition(challengeId);
    return definition.metadata;
  }

  Future<ChallengeAttempt> startAttempt(String challengeId) async {
    final definition = await _fetchDefinition(challengeId);
    return ChallengeAttempt(
      id: 'attempt_${definition.metadata.id}',
      challengeId: definition.metadata.id,
      startedAt: DateTime.now().toUtc(),
      questions: definition.questions,
    );
  }

  Future<RematchRequest> createRematchRequest({
    required String originalChallengeId,
    required int rematchIndex,
  }) async {
    final rematchChallengeId = _buildRematchId(originalChallengeId, rematchIndex);
    final definition = await _buildRematchDefinition(
      originalChallengeId: originalChallengeId,
      rematchChallengeId: rematchChallengeId,
      rematchIndex: rematchIndex,
    );
    final cacheKey = 'challenge_$rematchChallengeId';
    cache.setCachedContent(
      key: cacheKey,
      version: 1,
      value: json.encode(definition.toJson()),
    );
    return RematchRequest(
      id: 'rematch_${originalChallengeId}_$rematchIndex',
      originalChallengeId: originalChallengeId,
      rematchChallengeId: rematchChallengeId,
      createdAt: DateTime.now().toUtc(),
      challengerAccepted: true,
      opponentAccepted: false,
    );
  }

  Future<ChallengeResult> submitAttempt({
    required ChallengeAttempt attempt,
    required Map<String, ChallengeAnswerRecord> answers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 650));
    final answeredCount = answers.values.where((record) => record.choiceId != null).length;
    final seed = attempt.id.hashCode ^ attempt.challengeId.hashCode ^ answeredCount;
    final rng = Random(seed);
    final points = 900 + (answeredCount * 35) + rng.nextInt(350);
    final percentile = 62 + rng.nextDouble() * 30;
    final rank = 1 + rng.nextInt(5);
    final rankDelta = rng.nextInt(5) - 2;
    final completionTime = DateTime.now().difference(attempt.startedAt);
    final friends = [
      FriendRankEntry(name: 'Renata M.', points: 1780 + rng.nextInt(160), rank: 1, delta: 1),
      FriendRankEntry(name: 'You', points: points, rank: rank, delta: rankDelta),
      FriendRankEntry(name: 'Mike S.', points: 1540 + rng.nextInt(190), rank: 3, delta: -1),
      FriendRankEntry(name: 'Dinny K.', points: 1320 + rng.nextInt(180), rank: 4, delta: 2),
    ]..sort((a, b) => a.rank.compareTo(b.rank));

    return ChallengeResult(
      attemptId: attempt.id,
      challengeId: attempt.challengeId,
      points: points,
      percentile: percentile,
      rank: rank,
      rankDelta: rankDelta,
      completionTime: completionTime,
      friends: friends,
    );
  }

  Future<ChallengeDefinition> _fetchDefinition(String challengeId) async {
    final key = 'challenge_$challengeId';
    final jsonText = await cache.getCachedOrFetch(
      key: key,
      version: 1,
      fetcher: () => storage.downloadTextFile(key),
    );
    final decoded = json.decode(jsonText) as Map<String, dynamic>;
    return ChallengeDefinition.fromJson(decoded);
  }

  Future<ChallengeDefinition> _buildRematchDefinition({
    required String originalChallengeId,
    required String rematchChallengeId,
    required int rematchIndex,
  }) async {
    final sourceId = _pickRematchSourceId(
      originalChallengeId: originalChallengeId,
      rematchIndex: rematchIndex,
    );
    final source = await _fetchDefinition(sourceId);
    final metadata = ChallengeMetadata(
      id: rematchChallengeId,
      title: 'Rematch: ${source.metadata.title}',
      topic: source.metadata.topic,
      difficulty: source.metadata.difficulty,
      rules: source.metadata.rules,
      taunt: source.metadata.taunt,
      expiresAt: source.metadata.expiresAt,
    );
    return ChallengeDefinition(metadata: metadata, questions: source.questions);
  }

  String _pickRematchSourceId({
    required String originalChallengeId,
    required int rematchIndex,
  }) {
    final available = storage.listChallengeIds();
    final candidates = available.where((id) => id != originalChallengeId).toList();
    if (candidates.isEmpty) {
      throw StateError('No alternate challenges available for rematch.');
    }
    final seed = originalChallengeId.hashCode ^ rematchIndex.hashCode;
    final selected = candidates[seed.abs() % candidates.length];
    return selected;
  }

  String _buildRematchId(String originalChallengeId, int rematchIndex) {
    return 'rematch_${originalChallengeId}_${rematchIndex + 1}';
  }
}
