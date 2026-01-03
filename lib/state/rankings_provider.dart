import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rankings_content.dart';
import '../services/rankings_service.dart';
import 'categories_provider.dart';

final rankingsPeriodProvider = StateProvider<RankingsPeriod>((ref) {
  return RankingsPeriod.weekly;
});

final rankingsScopeProvider = StateProvider<RankingsScope>((ref) {
  return RankingsScope.global;
});

final rankingsTopicProvider = StateProvider<String?>((ref) => null);

final rankingsServiceProvider = Provider<RankingsService>((ref) {
  return RankingsService();
});

final rankingsProvider = FutureProvider<RankingsContent>((ref) async {
  final period = ref.watch(rankingsPeriodProvider);
  final categories = await ref.watch(categoriesProvider.future);
  return ref.read(rankingsServiceProvider).buildRankings(
        period: period,
        categories: categories,
      );
});
