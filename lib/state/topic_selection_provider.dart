import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/topic_selection_service.dart';
import 'auth_provider.dart';

final topicSelectionProvider = AsyncNotifierProvider<TopicSelectionController, Set<String>>(
  TopicSelectionController.new,
);

class TopicSelectionController extends AsyncNotifier<Set<String>> {
  late final TopicSelectionService _service;

  @override
  Future<Set<String>> build() async {
    _service = ref.read(topicSelectionServiceProvider);

    ref.listen<String?>(authUserIdProvider, (previous, next) {
      if (next == null || next == previous) return;
      unawaited(_syncAfterAuth(next));
    });

    return _service.loadSelectedTopics();
  }

  Future<void> toggleTopic(String topicId) async {
    final current = state.valueOrNull ?? await _service.loadSelectedTopics();
    final updated = {...current};
    if (!updated.add(topicId)) {
      updated.remove(topicId);
    }
    state = AsyncData(updated);
    await _persistAndMaybeSync(updated);
  }

  Future<void> setTopics(Set<String> topics) async {
    state = AsyncData(topics);
    await _persistAndMaybeSync(topics);
  }

  Future<void> _persistAndMaybeSync(Set<String> topics) async {
    await _service.persistSelectedTopics(topics);
    final userId = ref.read(authUserIdProvider);
    if (userId == null) {
      await _service.markPendingSync();
      return;
    }
    await _service.syncSelectedTopics(userId: userId, selectedIds: topics);
  }

  Future<void> _syncAfterAuth(String userId) async {
    final selected = state.valueOrNull ?? await _service.loadSelectedTopics();
    final pending = await _service.hasPendingSync();
    if (!pending && selected.isEmpty) return;
    await _service.syncSelectedTopics(userId: userId, selectedIds: selected);
  }
}
