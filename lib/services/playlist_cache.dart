/// In-memory cache with TTL. Used by playlist providers to avoid re-fetching.
class PlaylistCache<T> {
  T? _data;
  DateTime? _expiresAt;
  final Duration ttl;

  PlaylistCache({this.ttl = const Duration(minutes: 10)});

  T? get data {
    if (_data == null || _expiresAt == null) return null;
    if (DateTime.now().isAfter(_expiresAt!)) return null;
    return _data;
  }

  bool get isStale => _expiresAt == null || DateTime.now().isAfter(_expiresAt!);

  void set(T value) {
    _data = value;
    _expiresAt = DateTime.now().add(ttl);
  }

  void clear() {
    _data = null;
    _expiresAt = null;
  }
}

/// Map of caches by key (e.g. categoryId or "__all__") with TTL.
class KeyedPlaylistCache<T> {
  final Map<String, PlaylistCache<T>> _caches = {};
  final Duration ttl;

  KeyedPlaylistCache({this.ttl = const Duration(minutes: 10)});

  T? get(String key) => _caches[key]?.data;

  bool isFresh(String key) {
    final c = _caches[key];
    return c != null && !c.isStale;
  }

  void set(String key, T value) {
    _caches[key] ??= PlaylistCache<T>(ttl: ttl);
    _caches[key]!.set(value);
  }

  void clearKey(String key) => _caches.remove(key);

  void clear() => _caches.clear();
}
