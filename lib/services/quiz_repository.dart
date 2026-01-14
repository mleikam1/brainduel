import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_question.dart';
import '../models/game_session.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(FirebaseFunctions.instance, FirebaseFirestore.instance);
});

class QuizRepository {
  QuizRepository(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<GameSession> fetchSoloQuiz({required String categoryId}) async {
    try {
      final callable = _functions.httpsCallable('getQuiz');
      final result = await callable.call({
        'categoryId': categoryId,
        'mode': 'solo',
      });
      final data = _requireMap(result.data, 'getQuiz');
      final quizId = _requireString(
        data['quizId'] ?? data['gameId'] ?? data['sessionId'],
        'quizId',
      );
      final resolvedCategoryId = _requireString(
        data['categoryId'] ?? data['topicId'] ?? categoryId,
        'categoryId',
      );
      final questionIds = _requireStringList(data['questionIds'], 'questionIds');
      final questions = await _fetchQuestions(questionIds);

      return GameSession(
        gameId: quizId,
        topicId: resolvedCategoryId,
        questionsSnapshot: questions,
      );
    } on FirebaseFunctionsException catch (error) {
      throw QuizRepositoryException.fromFirebase(error);
    }
  }

  Future<List<GameQuestion>> _fetchQuestions(List<String> questionIds) async {
    final Map<String, GameQuestion> questionById = {};
    const chunkSize = 10;
    for (var i = 0; i < questionIds.length; i += chunkSize) {
      final end = (i + chunkSize > questionIds.length) ? questionIds.length : i + chunkSize;
      final chunk = questionIds.sublist(i, end);
      final snapshot = await _firestore
          .collection('questions')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        questionById[doc.id] = GameQuestion(
          id: doc.id,
          prompt: data['prompt'] as String,
          choices: List<String>.from(data['choices'] as List),
          difficulty: (data['difficulty'] as String?) ?? 'medium',
        );
      }
    }

    final questions = <GameQuestion>[];
    for (final id in questionIds) {
      final question = questionById[id];
      if (question == null) {
        throw StateError('Missing quiz question payload for $id.');
      }
      questions.add(question);
    }
    return questions;
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

  String _requireString(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw StateError('Missing $fieldName for quiz payload.');
  }

  List<String> _requireStringList(Object? value, String fieldName) {
    if (value is List) {
      final items = value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty);
      final result = items.toList();
      if (result.isNotEmpty) {
        return result;
      }
    }
    throw StateError('Missing $fieldName for quiz payload.');
  }
}

class QuizRepositoryException implements Exception {
  QuizRepositoryException(this.code, this.message, [this.details]);

  factory QuizRepositoryException.fromFirebase(FirebaseFunctionsException error) {
    return QuizRepositoryException(error.code, error.message, error.details);
  }

  final String code;
  final String? message;
  final Object? details;

  @override
  String toString() => 'QuizRepositoryException($code, $message, $details)';
}
