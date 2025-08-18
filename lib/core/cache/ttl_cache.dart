class TtlCache<K, V> {
  final Duration ttl;
  final int maxEntries;
  final _map = <K, _Entry<V>>{};

  TtlCache({required this.ttl, this.maxEntries = 200});

  V? get(K key) {
    final e = _map[key];
    if (e == null) return null;
    if (DateTime.now().isAfter(e.expiresAt)) {
      _map.remove(key);
      return null;
    }
    return e.value;
  }

  void set(K key, V value) {
    if (_map.length >= maxEntries) {
      _map.remove(_map.keys.first);
    }
    _map[key] = _Entry(value, DateTime.now().add(ttl));
  }

  void invalidate(K key) => _map.remove(key);
  void clear() => _map.clear();
}

class _Entry<V> {
  final V value;
  final DateTime expiresAt;
  _Entry(this.value, this.expiresAt);
}
