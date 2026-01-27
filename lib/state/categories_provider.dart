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

class CategoriesManifest {
  CategoriesManifest({
    required this.categories,
    required this.packMap,
  });

  // Category registry used across Home/Discover/Rankings.
  // `id` values must match backend topicId values (Firestore topics/questions).
  final List<Category> categories;
  // Maps categoryId -> packId for local/demo packs.
  final Map<String, String> packMap;
}

final categoriesManifestProvider = FutureProvider<CategoriesManifest>((ref) async {
  final storage = ref.read(storageContentServiceProvider);
  final cache = ref.read(contentCacheServiceProvider);

  // Category definitions are delivered via a manifest so we can update the
  // registry without hardcoding lists inside widgets.
  final jsonText = await cache.getCachedOrFetch(
    key: 'categories_manifest',
    version: 2,
    fetcher: () => storage.downloadTextFile('categories'),
  );

  final decodedRaw = json.decode(jsonText);
  if (decodedRaw is! Map) {
    throw StateError('Invalid categories manifest payload.');
  }
  final decoded = Map<String, dynamic>.from(decodedRaw);
  final rawCategories = decoded['categories'];
  if (rawCategories is! List) {
    throw StateError('Invalid categories list payload.');
  }
  final list = List<Map<String, dynamic>>.from(
    rawCategories.map((entry) {
      if (entry is! Map) {
        throw StateError('Invalid category payload.');
      }
      return Map<String, dynamic>.from(entry);
    }),
  );
  final categories = list.map(Category.fromJson).toList();
  final rawPackMap = decoded['packMap'];
  final packMap = rawPackMap is Map
      ? Map<String, dynamic>.from(rawPackMap)
          .map((key, value) => MapEntry(key.toString(), value.toString()))
      : <String, String>{};
  return CategoriesManifest(categories: categories, packMap: packMap);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final manifest = await ref.watch(categoriesManifestProvider.future);
  return manifest.categories.where((c) => c.enabled).toList();
});

final categoryPackIdProvider = FutureProvider.family<String, String>((ref, categoryId) async {
  final manifest = await ref.watch(categoriesManifestProvider.future);
  return manifest.packMap[categoryId] ?? '';
});

final categoryDetailProvider = Provider.family<CategoryDetail, Category>((ref, category) {
  // Hardcoded metadata for the demo experience; add new entries here when
  // shipping new categories, or move to a remote manifest later.
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
    'geography': (
    subtitle: 'World knowledge',
    description: 'Explore capitals, landmarks, and global geography in fast rounds.',
    questionCount: 20,
    points: 1350,
    packCount: 2,
    ),
    'movies': (
    subtitle: 'Cinematic moments',
    description: 'From classics to blockbusters, test your movie trivia instincts.',
    questionCount: 20,
    points: 1350,
    packCount: 2,
    ),
    'music': (
    subtitle: 'Soundtrack savvy',
    description: 'Hit the right notes across artists, genres, and iconic tracks.',
    questionCount: 20,
    points: 1300,
    packCount: 2,
    ),
    'entertainment': (
    subtitle: 'Pop culture pulse',
    description: 'TV, streaming, games, and fan favorites across the entertainment world.',
    questionCount: 20,
    points: 1300,
    packCount: 2,
    ),
    'food': (
    subtitle: 'Flavor rounds',
    description: 'From global dishes to kitchen staples, prove your foodie knowledge.',
    questionCount: 20,
    points: 1250,
    packCount: 2,
    ),
    'animals': (
    subtitle: 'Wild facts',
    description: 'Celebrate wildlife, habitats, and animal kingdom surprises.',
    questionCount: 20,
    points: 1250,
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
