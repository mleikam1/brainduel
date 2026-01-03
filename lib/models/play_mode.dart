enum PlayDestinationType {
  categories,
  challenge,
}

class PlayDestination {
  final PlayDestinationType type;
  final String? challengeId;

  const PlayDestination.categories() : type = PlayDestinationType.categories, challengeId = null;

  const PlayDestination.challenge(this.challengeId) : type = PlayDestinationType.challenge;
}

class PlayMode {
  final String id;
  final String title;
  final String description;
  final String riskLabel;
  final String rewardLabel;
  final String ctaLabel;
  final bool ranked;
  final PlayDestination destination;

  const PlayMode({
    required this.id,
    required this.title,
    required this.description,
    required this.riskLabel,
    required this.rewardLabel,
    required this.ctaLabel,
    required this.ranked,
    required this.destination,
  });
}
