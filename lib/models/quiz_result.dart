import 'package:flutter/foundation.dart';

@immutable
class QuizResultAnswer {
  const QuizResultAnswer({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.correctAnswerIndex,
  });

  final String questionId;
  final int selectedAnswerIndex;
  final int correctAnswerIndex;
}

@immutable
class QuizResult {
  QuizResult({
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    required List<QuizResultAnswer> answers,
  }) : answers = List.unmodifiable(answers);

  final int totalQuestions;
  final int correctCount;
  final int score;
  final List<QuizResultAnswer> answers;
}
