import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final topicSelectionRemoteServiceProvider = Provider<TopicSelectionRemoteService>((ref) {
  return TopicSelectionRemoteService();
});

final topicSelectionServiceProvider = Provider<TopicSelectionService>((ref) {
  return TopicSelectionService(ref.read(topicSelectionRemoteServiceProvider));
});

class TopicSelectionService {
  TopicSelectionService(this._remoteService);

  final TopicSelectionRemoteService _remoteService;

  static const _selectedTopicsKey = 'selected_topic_ids';
  static const _pendingSyncKey = 'selected_topic_ids_pending_sync';

  Future<Set<String>> loadSelectedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_selectedTopicsKey) ?? <String>[];
    return stored.toSet();
  }

  Future<void> persistSelectedTopics(Set<String> selectedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedTopicsKey, selectedIds.toList());
  }

  Future<void> markPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSyncKey, true);
  }

  Future<bool> hasPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pendingSyncKey) ?? false;
  }

  Future<void> syncSelectedTopics({
    required String userId,
    required Set<String> selectedIds,
  }) async {
    await _remoteService.syncTopics(
      userId: userId,
      topicIds: selectedIds.toList(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingSyncKey, false);
  }
}

class TopicSelectionRemoteService {
  Future<void> syncTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    debugPrint('[topic sync] user=$userId topics=${topicIds.join(',')}');
  }
}
