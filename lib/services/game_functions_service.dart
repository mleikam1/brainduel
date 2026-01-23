import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_answer.dart';
import '../models/game_session.dart';
import '../models/solo_pack_leaderboard.dart';

final gameFunctionsServiceProvider = Provider<GameFunctionsService>((ref) {
  return GameFunctionsService(FirebaseFunctions.instance);
});

class GameFunctionsService {
  GameFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  Future<GameSession> createGame({
    required String topicId,
    required String mode,
    String? triviaPackId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createGame');
      final payload = {
        'topicId': topicId,
        'mode': mode,
        if (triviaPackId != null && triviaPackId.trim().isNotEmpty)
          'triviaPackId': triviaPackId.trim(),
      };
      final result = await callable.call(payload);
      final data = _requireMap(result.data, 'createGame');
      final session = GameSession.fromJson(data);
      return session;
    } on FirebaseFunctionsException catch (error) {
      _logCallableError('createGame', error);
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<GameSession> loadGame(String gameId) async {
    try {
      final callable = _functions.httpsCallable('loadGame');
      final result = await callable.call({'gameId': gameId});
      final data = _requireMap(result.data, 'loadGame');
      return GameSession.fromJson(data);
    } on FirebaseFunctionsException catch (error) {
      _logCallableError('loadGame', error);
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
      _logCallableError('getSharedQuiz', error);
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<GameSession> getTriviaPack(String triviaPackId) async {
    try {
      final callable = _functions.httpsCallable('getTriviaPack');
      final result = await callable.call({'triviaPackId': triviaPackId});
      final data = _requireMap(result.data, 'getTriviaPack');
      return GameSession.fromJson(data);
    } on FirebaseFunctionsException catch (error) {
      _logCallableError('getTriviaPack', error);
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
      _logCallableError('createSharedQuiz', error);
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
      _logCallableError('completeGame', error);
      throw GameFunctionsException.fromFirebase(error);
    }
  }

  Future<({
    int score,
    int maxScore,
    int? correct,
    int? total,
    SoloPackLeaderboard leaderboard,
  })> submitSoloScore({
    required String triviaPackId,
    required int score,
    int? correct,
    int? total,
    int? durationSeconds,
    List<GameAnswer>? answers,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitSoloScore');
      final result = await callable.call({
        'triviaPackId': triviaPackId,
        'score': score,
        'metadata': {
          if (durationSeconds != null) 'durationSeconds': durationSeconds,
          if (correct != null) 'correct': correct,
          if (total != null) 'total': total,
        },
        if (answers != null)
          'answers': answers
              .map((answer) => {
                    'questionId': answer.questionId,
                    'selectedIndex': answer.selectedIndex,
                  })
              .toList(),
      });
      final data = _requireMap(result.data, 'submitSoloScore');
      final leaderboardJson = _requireMap(data['leaderboard'], 'submitSoloScore.leaderboard');
      return (
        score: (data['score'] as num).toInt(),
        maxScore: (data['maxScore'] as num).toInt(),
        correct: (data['correct'] as num?)?.toInt(),
        total: (data['total'] as num?)?.toInt(),
        leaderboard: SoloPackLeaderboard.fromJson(leaderboardJson),
      );
    } on FirebaseFunctionsException catch (error) {
      _logCallableError('submitSoloScore', error);
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
    throw GameFunctionsException(
      'internal',
      'Unexpected $functionName response payload.',
    );
  }

  void _logCallableError(String name, FirebaseFunctionsException error) {
    debugPrint(
      'Callable $name failed: code=${error.code} message=${error.message} details=${error.details}',
    );
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
