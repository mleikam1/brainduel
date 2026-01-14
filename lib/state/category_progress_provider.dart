import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_progress.dart';
import '../models/category_weekly_indicator.dart';
import '../services/category_progress_service.dart';
import '../services/week_key_service.dart';
import 'auth_provider.dart';

final currentWeekKeyProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(authUserIdProvider);
  final userReady = ref.watch(userBootstrapReadyProvider);
  if (userId == null || userId.isEmpty || !userReady) {
    return null;
  }
  final service = ref.read(weekKeyServiceProvider);
  return service.fetchWeekKey();
});

final categoryProgressMapProvider = StreamProvider<Map<String, CategoryProgress>>((ref) {
  final userId = ref.watch(authUserIdProvider);
  final userReady = ref.watch(userBootstrapReadyProvider);
  if (userId == null || userId.isEmpty || !userReady) {
    return Stream.value(<String, CategoryProgress>{});
  }
  final service = ref.read(categoryProgressServiceProvider);
  return service.watchProgress(userId);
});

final categoryWeeklyIndicatorProvider =
    Provider.family<CategoryWeeklyIndicator, String>((ref, categoryId) {
  final currentWeekKey = ref.watch(currentWeekKeyProvider).asData?.value;
  final progressMap = ref.watch(categoryProgressMapProvider).asData?.value;
  if (currentWeekKey == null || progressMap == null) {
    return const CategoryWeeklyIndicator();
  }

  final progress = progressMap[categoryId];
  if (progress == null || progress.weekKey.isEmpty) {
    return const CategoryWeeklyIndicator();
  }

  final isSameWeek = progress.weekKey == currentWeekKey;
  if (!isSameWeek) {
    return const CategoryWeeklyIndicator(
      state: CategoryWeeklyState.fresh,
      showWeeklyRefresh: true,
    );
  }

  if (progress.exhaustedCount > 0) {
    return const CategoryWeeklyIndicator(state: CategoryWeeklyState.completed);
  }

  return const CategoryWeeklyIndicator();
});
