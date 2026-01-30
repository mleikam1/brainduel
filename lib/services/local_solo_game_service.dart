import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_question.dart';
import '../models/game_session.dart';
import '../models/trivia_pack.dart';
import '../services/content_cache_service.dart';
import '../services/storage_content_service.dart';
import '../services/trivia_session_builder.dart';
import '../state/categories_provider.dart';

const int kMinimumSoloQuestionCount = kTriviaQuestionCount;

class LocalSoloGameSession {
  LocalSoloGameSession({
    required this.session,
    required this.correctChoiceByQuestionId,
  });

  final GameSession session;
  final Map<String, String> correctChoiceByQuestionId;
}

final localSoloGameServiceProvider = Provider<LocalSoloGameService>((ref) {
  return LocalSoloGameService(
    storage: ref.read(storageContentServiceProvider),
    cache: ref.read(contentCacheServiceProvider),
    builder: TriviaSessionBuilder(),
  );
});

class LocalSoloGameService {
  LocalSoloGameService({
    required this.storage,
    required this.cache,
    required this.builder,
  });

  final StorageContentService storage;
  final ContentCacheService cache;
  final TriviaSessionBuilder builder;

  Future<LocalSoloGameSession> createSession({
    required String categoryId,
    required String packId,
    int? seed,
  }) async {
    // Trivia packs are resolved via the category manifest (categoryId -> packId)
    // so questions stay aligned with the selected category.
    final jsonText = await cache.getCachedOrFetch(
      key: 'pack_$packId',
      version: 1,
      fetcher: () => storage.downloadTextFile(packId),
    );
    final decodedRaw = json.decode(jsonText);
    if (decodedRaw is! Map) {
      throw StateError('Invalid trivia pack payload.');
    }
    final decoded = Map<String, dynamic>.from(decodedRaw);
    final pack = TriviaPack.fromJson(decoded);
    if (pack.categoryId != categoryId) {
      throw StateError(
        'Pack $packId belongs to ${pack.categoryId}, but $categoryId was requested.',
      );
    }
    if (pack.questions.length < kMinimumSoloQuestionCount) {
      throw StateError(
        'Pack $packId has ${pack.questions.length} questions; '
        '$kMinimumSoloQuestionCount required for solo matches.',
      );
    }

    final session = builder.buildSession(
      pack: pack,
      mode: 'solo',
      seed: seed,
    );

    final correctById = <String, String>{};
    final questionsSnapshot = session.questions.map((question) {
      final displayAnswers = question.displayAnswers;
      final correct = displayAnswers.firstWhere((answer) => answer.correct);
      correctById[question.id] = correct.id;
      return GameQuestion(
        id: question.id,
        prompt: question.question,
        choices: displayAnswers.map((answer) => answer.text).toList(),
        choiceIds: displayAnswers.map((answer) => answer.id).toList(),
        difficulty: 'standard',
        correctAnswerId: correct.id,
      );
    }).toList();

    return LocalSoloGameSession(
      session: GameSession(
        gameId: 'local_${session.sessionId}',
        topicId: categoryId,
        questionsSnapshot: questionsSnapshot,
      ),
      correctChoiceByQuestionId: correctById,
    );
  }
}
