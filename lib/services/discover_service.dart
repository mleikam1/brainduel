import '../models/category.dart';
import '../models/discover_content.dart';

class DiscoverService {
  DiscoverContent buildContent(List<Category> categories) {
    final topics = categories.map(_buildTopic).toList();

    // Assumption: editorial collections are curated locally until a backend feed exists.
    final collections = [
      DiscoverCollection(
        title: 'Hardest Geography Packs',
        description: 'Tough terrain, tougher questions.',
        topicIds: topics.map((topic) => topic.category.id).take(2).toList(),
      ),
      DiscoverCollection(
        title: 'Speed Round Staples',
        description: 'Fast, sharp, and competitive.',
        topicIds: topics.map((topic) => topic.category.id).skip(1).take(2).toList(),
      ),
    ];

    final sponsored = <String>{
      if (categories.isNotEmpty) categories.first.id,
    };

    return DiscoverContent(
      topics: topics,
      collections: collections,
      sponsoredTopicIds: sponsored,
    );
  }

  DiscoverTopic _buildTopic(Category category) {
    final detail = _detailForCategory(category.id);
    final difficulty = _difficultyForCategory(category.id);
    return DiscoverTopic(
      category: category,
      difficulty: difficulty,
      subtitle: detail.subtitle,
      packCount: detail.packCount,
      questionCount: detail.questionCount,
    );
  }

  DiscoverDifficulty _difficultyForCategory(String id) {
    switch (id) {
      case 'science':
        return DiscoverDifficulty.hard;
      case 'history':
        return DiscoverDifficulty.medium;
      case 'sports':
        return DiscoverDifficulty.easy;
      default:
        return DiscoverDifficulty.medium;
    }
  }

  _DiscoverDetail _detailForCategory(String id) {
    // Assumption: reuse the starter detail mapping until pack metadata is surfaced from the backend.
    switch (id) {
      case 'sports':
        return const _DiscoverDetail(
          subtitle: 'Elite competitions',
          packCount: 3,
          questionCount: 20,
        );
      case 'history':
        return const _DiscoverDetail(
          subtitle: 'Historic milestones',
          packCount: 3,
          questionCount: 20,
        );
      case 'science':
        return const _DiscoverDetail(
          subtitle: 'Future-forward facts',
          packCount: 2,
          questionCount: 20,
        );
      default:
        return const _DiscoverDetail(
          subtitle: 'Competitive knowledge',
          packCount: 2,
          questionCount: 12,
        );
    }
  }
}

class _DiscoverDetail {
  final String subtitle;
  final int packCount;
  final int questionCount;

  const _DiscoverDetail({
    required this.subtitle,
    required this.packCount,
    required this.questionCount,
  });
}
