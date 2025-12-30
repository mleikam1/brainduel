class ContentCacheService {
  final Map<String, String> _cache = {};
  final Map<String, int> _versions = {};

  Future<String> getCachedOrFetch({
    required String key,
    required int version,
    required Future<String> Function() fetcher,
  }) async {
    final cached = _cache[key];
    final cachedVer = _versions[key];
    if (cached != null && cachedVer == version) return cached;

    try {
      final value = await fetcher();
      _cache[key] = value;
      _versions[key] = version;
      return value;
    } catch (_) {
      // Fallback to stale cache if available
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> clearAllCachedContent() async {
    _cache.clear();
    _versions.clear();
  }

  void setCachedContent({
    required String key,
    required int version,
    required String value,
  }) {
    _cache[key] = value;
    _versions[key] = version;
  }
}
