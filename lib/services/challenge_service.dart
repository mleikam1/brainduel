import 'dart:convert';
import '../models/challenge.dart';
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
}
