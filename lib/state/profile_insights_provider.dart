import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_insights.dart';
import '../services/profile_insights_service.dart';
import 'categories_provider.dart';
import 'user_stats_provider.dart';

final profileInsightsServiceProvider = Provider<ProfileInsightsService>((ref) {
  return ProfileInsightsService();
});

final profileInsightsProvider = FutureProvider<ProfileInsights>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final stats = ref.watch(userStatsProvider);
  return ref.read(profileInsightsServiceProvider).buildInsights(
        stats: stats,
        categories: categories,
      );
});
