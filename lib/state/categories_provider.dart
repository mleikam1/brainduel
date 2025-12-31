import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/category_detail.dart';
import '../models/leaderboard_entry.dart';
import '../services/storage_content_service.dart';
import '../services/content_cache_service.dart';

final storageContentServiceProvider = Provider<StorageContentService>((ref) {
  return StorageContentService();
});

final contentCacheServiceProvider = Provider<ContentCacheService>((ref) {
  return ContentCacheService();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final storage = ref.read(storageContentServiceProvider);
  final cache = ref.read(contentCacheServiceProvider);

  final jsonText = await cache.getCachedOrFetch(
    key: 'categories_manifest',
    version: 1,
    fetcher: () => storage.downloadTextFile('categories'),
  );

  final decoded = json.decode(jsonText) as Map<String, dynamic>;
  final list = (decoded['categories'] as List).cast<Map<String, dynamic>>();
  return list.map(Category.fromJson).where((c) => c.enabled).toList();
});

final categoryPackPathProvider = Provider.family<String, String>((ref, categoryId) {
  // Derived from the demo manifest in StorageContentService.
  // When you move to Firebase, this mapping will come from manifest JSON.
  const mapping = {
    'sports': 'pack_sports',
    'history': 'pack_history',
    'science': 'pack_science',
  };
  return mapping[categoryId] ?? 'pack_sports';
});

final categoryDetailProvider = Provider.family<CategoryDetail, Category>((ref, category) {
  const details = {
    'sports': (
    subtitle: 'Elite competitions',
    description: 'Test your knowledge across global leagues, records, and iconic matchups.',
    questionCount: 20,
    points: 1500,
    packCount: 3,
    ),
    'history': (
    subtitle: 'Historic milestones',
    description: 'From ancient empires to modern revolutions, prove your command of the past.',
    questionCount: 20,
    points: 1400,
    packCount: 3,
    ),
    'science': (
    subtitle: 'Future-forward facts',
    description: 'Challenge your grasp of physics, chemistry, and the universe beyond.',
    questionCount: 20,
    points: 1300,
    packCount: 2,
    ),
  };

  final data = details[category.id];
  return CategoryDetail(
    category: category,
    subtitle: data?.subtitle ?? 'Competitive knowledge',
    description: data?.description ?? 'Sharpen your trivia instincts with fast, focused rounds.',
    questionCount: data?.questionCount ?? 12,
    points: data?.points ?? 1200,
    packCount: data?.packCount ?? 2,
  );
});

final categoryRankingsProvider = Provider.family<List<LeaderboardEntry>, String>((ref, categoryId) {
  const entries = [
    LeaderboardEntry(name: 'Renata M.', points: 1840, time: Duration(minutes: 1, seconds: 12), rank: 1),
    LeaderboardEntry(name: 'Monica R.', points: 1720, time: Duration(minutes: 1, seconds: 18), rank: 2),
    LeaderboardEntry(name: 'Mike S.', points: 1650, time: Duration(minutes: 1, seconds: 26), rank: 3),
  ];
  return entries;
});
