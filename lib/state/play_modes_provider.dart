import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/play_mode.dart';
import '../services/play_mode_service.dart';
import 'categories_provider.dart';

final playModeServiceProvider = Provider<PlayModeService>((ref) {
  return PlayModeService(storage: ref.read(storageContentServiceProvider));
});

final playModesProvider = Provider<List<PlayMode>>((ref) {
  return ref.read(playModeServiceProvider).fetchModes();
});
