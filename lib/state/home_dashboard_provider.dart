import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_dashboard.dart';
import '../services/home_dashboard_service.dart';
import 'categories_provider.dart';
import 'challenge_providers.dart';
import 'topic_selection_provider.dart';

final homeDashboardServiceProvider = Provider<HomeDashboardService>((ref) {
  return HomeDashboardService(
    challengeService: ref.read(challengeServiceProvider),
    storage: ref.read(storageContentServiceProvider),
  );
});

final homeDashboardProvider = FutureProvider<HomeDashboard>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final selectedTopics = await ref.watch(topicSelectionProvider.future);
  return ref.read(homeDashboardServiceProvider).buildDashboard(
        categories: categories,
        selectedTopicIds: selectedTopics,
      );
});
