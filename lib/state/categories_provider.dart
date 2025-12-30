import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
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
