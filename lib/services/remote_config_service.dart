class RemoteConfigService {
  Future<void> initAndFetch() async {
    // No-op for local MVP (Firebase removed).
  }

  int get defaultSessionSize => 10;
  List<String> get modesEnabled => const ['classic'];
}
