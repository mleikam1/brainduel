class GameAnswer {
  final String questionId;
  final String choice;

  const GameAnswer({
    required this.questionId,
    required this.choice,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'choice': choice,
    };
  }
}
