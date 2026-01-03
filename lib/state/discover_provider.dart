import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discover_content.dart';
import '../services/discover_service.dart';
import 'categories_provider.dart';

class DiscoverFilter {
  final String query;
  final DiscoverDifficulty? difficulty;

  const DiscoverFilter({
    required this.query,
    required this.difficulty,
  });

  DiscoverFilter copyWith({
    String? query,
    DiscoverDifficulty? difficulty,
  }) {
    return DiscoverFilter(
      query: query ?? this.query,
      difficulty: difficulty,
    );
  }
}

class DiscoverFilterNotifier extends StateNotifier<DiscoverFilter> {
  DiscoverFilterNotifier() : super(const DiscoverFilter(query: '', difficulty: null));

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void updateDifficulty(DiscoverDifficulty? difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }
}

final discoverFilterProvider = StateNotifierProvider<DiscoverFilterNotifier, DiscoverFilter>((ref) {
  return DiscoverFilterNotifier();
});

final discoverServiceProvider = Provider<DiscoverService>((ref) {
  return DiscoverService();
});

final discoverContentProvider = FutureProvider<DiscoverContent>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  return ref.read(discoverServiceProvider).buildContent(categories);
});
