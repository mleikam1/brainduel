class GameAnswer {
  final String questionId;
  final String choice;
  final int selectedIndex;

  const GameAnswer({
    required this.questionId,
    required this.choice,
    required this.selectedIndex,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'choice': choice,
      'selectedIndex': selectedIndex,
    };
  }
}
