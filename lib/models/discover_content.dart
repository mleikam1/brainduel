import 'category.dart';

enum DiscoverDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class DiscoverTopic {
  final Category category;
  final DiscoverDifficulty difficulty;
  final String subtitle;
  final int packCount;
  final int questionCount;

  const DiscoverTopic({
    required this.category,
    required this.difficulty,
    required this.subtitle,
    required this.packCount,
    required this.questionCount,
  });
}

class DiscoverCollection {
  final String title;
  final String description;
  final List<String> topicIds;

  const DiscoverCollection({
    required this.title,
    required this.description,
    required this.topicIds,
  });
}

class DiscoverContent {
  final List<DiscoverTopic> topics;
  final List<DiscoverCollection> collections;
  final Set<String> sponsoredTopicIds;

  const DiscoverContent({
    required this.topics,
    required this.collections,
    required this.sponsoredTopicIds,
  });
}
