import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_answer.dart';
import '../models/game_session.dart';

final gameFunctionsServiceProvider = Provider<GameFunctionsService>((ref) {
  return GameFunctionsService(FirebaseFunctions.instance);
});

class GameFunctionsService {
  GameFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  Future<GameSession> createGame({
    required String topicId,
    required String triviaPackId,
    required String mode,
  }) async {
    try {
      final callable = _functions.httpsCallable('createGame');
      final result = await callable.call({
        'topicId': topicId,
        'triviaPackId': triviaPackId,
        'mode': mode,
      });
      final data = _requireMap(result.data, 'createGame');
      final rawQuestions = data['questionsSnapshot'] ?? data['questions'];
      if (rawQuestions is! List || rawQuestions.isEmpty) {
        throw GameFunctionsException('failed-precondition', 'NO_QUESTIONS_AVAILABLE');
      }
      final session = GameSession.fromJson(data);
      if (session.questionsSnapshot.isEmpty) {
        throw GameFunctionsException('failed-precondition', 'NO_QUESTIONS_AVAILABLE');
      }
      return session;
    } on FirebaseFunctionsException catch (error) {
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<int> fetchQuestionCountForTopic(String topicId) async {
    final trimmedTopicId = topicId.trim();
    if (trimmedTopicId.isEmpty) {
      return 0;
    }
    try {
      final aggregate = await FirebaseFirestore.instance
          .collection('questions')
          .where('topicId', isEqualTo: trimmedTopicId)
          .count()
          .get();
      return (aggregate.count as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<GameSession> loadGame(String gameId) async {
    try {
      final callable = _functions.httpsCallable('loadGame');
      final result = await callable.call({'gameId': gameId});
      final data = _requireMap(result.data, 'loadGame');
      return GameSession.fromJson(data);
    } on FirebaseFunctionsException catch (error) {
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<GameSession> getSharedQuiz(String quizId) async {
    try {
      final callable = _functions.httpsCallable('getSharedQuiz');
      final result = await callable.call({'quizId': quizId});
      final data = _requireMap(result.data, 'getSharedQuiz');
      return GameSession.fromJson(data);
    } on FirebaseFunctionsException catch (error) {
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<({String quizId, String categoryId})> createSharedQuiz({
    required String categoryId,
    required List<String> questionIds,
    required int quizSize,
  }) async {
    try {
      final callable = _functions.httpsCallable('createSharedQuiz');
      final result = await callable.call({
        'categoryId': categoryId,
        'questionIds': questionIds,
        'quizSize': quizSize,
      });
      final data = _requireMap(result.data, 'createSharedQuiz');
      return (
        quizId: data['quizId'] as String,
        categoryId: (data['categoryId'] as String?) ?? categoryId,
      );
    } on FirebaseFunctionsException catch (error) {
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<({int score, int maxScore, int? correct, int? total})> completeGame(
    String gameId,
    List<GameAnswer> answers,
  ) async {
    try {
      final callable = _functions.httpsCallable('completeGame');
      final result = await callable.call({
        'gameId': gameId,
        'answers': answers.map((answer) => answer.toJson()).toList(),
      });
      final data = _requireMap(result.data, 'completeGame');
      return (
        score: (data['score'] as num).toInt(),
        maxScore: (data['maxScore'] as num).toInt(),
        correct: (data['correct'] as num?)?.toInt(),
        total: (data['total'] as num?)?.toInt(),
      );
    } on FirebaseFunctionsException catch (error) {
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Map<String, dynamic> _requireMap(Object? payload, String functionName) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Unexpected $functionName response payload.');
  }
}

class GameFunctionsException implements Exception {
  GameFunctionsException(this.code, this.message, [this.details]);

  factory GameFunctionsException.fromFirebase(FirebaseFunctionsException error) {
    return GameFunctionsException(error.code, error.message, error.details);
  }

  final String code;
  final String? message;
  final Object? details;

  @override
  String toString() => 'GameFunctionsException($code, $message, $details)';
}
