class ChallengeAnswerRecord {
  final int? choiceIndex;
  final String? choiceId;
  final int answerTimeMs;

  const ChallengeAnswerRecord({
    required this.choiceIndex,
    required this.choiceId,
    required this.answerTimeMs,
  });
}
