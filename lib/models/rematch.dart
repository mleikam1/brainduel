class RematchRequest {
  final String id;
  final String originalChallengeId;
  final String rematchChallengeId;
  final DateTime createdAt;
  final bool challengerAccepted;
  final bool opponentAccepted;

  const RematchRequest({
    required this.id,
    required this.originalChallengeId,
    required this.rematchChallengeId,
    required this.createdAt,
    required this.challengerAccepted,
    required this.opponentAccepted,
  });

  RematchRequest copyWith({
    bool? challengerAccepted,
    bool? opponentAccepted,
  }) {
    return RematchRequest(
      id: id,
      originalChallengeId: originalChallengeId,
      rematchChallengeId: rematchChallengeId,
      createdAt: createdAt,
      challengerAccepted: challengerAccepted ?? this.challengerAccepted,
      opponentAccepted: opponentAccepted ?? this.opponentAccepted,
    );
  }
}
