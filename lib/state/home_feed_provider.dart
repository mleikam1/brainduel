import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_feed.dart';
import '../services/home_feed_service.dart';

final homeFeedServiceProvider = Provider<HomeFeedService>((ref) {
  return HomeFeedService();
});

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final service = ref.read(homeFeedServiceProvider);
  return service.fetchHomeFeed();
});
