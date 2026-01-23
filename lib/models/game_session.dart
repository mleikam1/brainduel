import 'game_question.dart';

class GameSession {
  final String gameId;
  final String topicId;
  final List<GameQuestion> questionsSnapshot;
  final GameSelectionMeta? selectionMeta;
  final String? triviaPackId;

  const GameSession({
    required this.gameId,
    required this.topicId,
    required this.questionsSnapshot,
    this.selectionMeta,
    this.triviaPackId,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questionsSnapshot'] ?? json['questions'];
    final questionsJson = (rawQuestions as List).cast<Map<String, dynamic>>();
    final questions = questionsJson.map(GameQuestion.fromJson).toList();
    final topicId = json['topicId'] ?? json['categoryId'];
    if (topicId == null) {
      throw StateError('Missing topicId for game session payload.');
    }
    final rawSelectionMeta = json['selectionMeta'];
    final selectionMeta = rawSelectionMeta is Map
        ? GameSelectionMeta.fromJson(Map<String, dynamic>.from(rawSelectionMeta))
        : null;
    return GameSession(
      gameId: (json['gameId'] ?? json['quizId'] ?? json['sessionId']) as String,
      topicId: topicId as String,
      questionsSnapshot: questions,
      selectionMeta: selectionMeta,
      triviaPackId: json['triviaPackId'] as String?,
    );
  }
}

class GameSelectionMeta {
  final bool exhaustedThisPick;
  final int poolSize;
  final String weekKey;

  const GameSelectionMeta({
    required this.exhaustedThisPick,
    required this.poolSize,
    required this.weekKey,
  });

  factory GameSelectionMeta.fromJson(Map<String, dynamic> json) {
    return GameSelectionMeta(
      exhaustedThisPick: (json['exhaustedThisPick'] as bool?) ?? false,
      poolSize: (json['poolSize'] as num?)?.toInt() ?? 0,
      weekKey: (json['weekKey'] as String?) ?? '',
    );
  }
}
