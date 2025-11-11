// lib/src/features/tmdb/data/datasources/tmdb_cache_data_source.dart

import '../../../core/storage/repositories/content_cache_repository.dart';
import '../../../core/storage/services/cache_policy.dart';

/// Cache TMDB combinant :
/// - **mémoïzation mémoire courte** (LRU + TTL 30–60s par défaut)
/// - **persistance** via [ContentCacheRepository] (TTL 7 jours)
///
/// Objectif : éviter les re-hits réseau lors d’un scroll (mêmes IDs demandés
/// en rafale) tout en conservant un cache durable entre sessions.
class TmdbCacheDataSource {
  TmdbCacheDataSource(
    this._cache, {
    Duration memoTtl = const Duration(seconds: 45),
    int memoCapacity = 512,
  })  : _memoTtl = memoTtl,
        _memo = _LruMemo<String, Map<String, dynamic>>(memoCapacity);

  final ContentCacheRepository _cache;

  // 7 jours pour la couche persistée
  static const CachePolicy detailPolicy = CachePolicy(ttl: Duration(days: 7));

  // Mémo court (mémoire process)
  final Duration _memoTtl;
  final _LruMemo<String, Map<String, dynamic>> _memo;

  String _movieKey(int id) => 'tmdb_movie_detail_$id';
  String _tvKey(int id) => 'tmdb_tv_detail_$id';

  /// ----- MOVIE -----

  Future<Map<String, dynamic>?> getMovieDetail(
    int id, {
    Duration? memoTtl,
    CachePolicy? policyOverride,
  }) async {
    final key = _movieKey(id);

    // 1) Mémo mémoire
    final memo = _memo.getIfFresh(key);
    if (memo != null) return memo;

    // 2) Cache persistant (TTL overridable)
    final data = await _cache.getWithPolicy(key, policyOverride ?? detailPolicy);
    if (data is Map<String, dynamic>) {
      _memo.put(key, data, ttl: memoTtl ?? _memoTtl);
      return data;
    }
    // Donnée corrompue ou inattendue : on renvoie null (laisser la couche au-dessus décider)
    return null;
  }

  Future<void> putMovieDetail(
    int id,
    Map<String, dynamic> json, {
    Duration? memoTtl,
  }) async {
    final key = _movieKey(id);
    _memo.put(key, json, ttl: memoTtl ?? _memoTtl);
    await _cache.put(key: key, type: 'tmdb_detail', payload: json);
  }

  /// ----- TV -----

  Future<Map<String, dynamic>?> getTvDetail(
    int id, {
    Duration? memoTtl,
    CachePolicy? policyOverride,
  }) async {
    final key = _tvKey(id);

    final memo = _memo.getIfFresh(key);
    if (memo != null) return memo;

    final data = await _cache.getWithPolicy(key, policyOverride ?? detailPolicy);
    if (data is Map<String, dynamic>) {
      _memo.put(key, data, ttl: memoTtl ?? _memoTtl);
      return data;
    }
    return null;
  }

  Future<void> putTvDetail(
    int id,
    Map<String, dynamic> json, {
    Duration? memoTtl,
  }) async {
    final key = _tvKey(id);
    _memo.put(key, json, ttl: memoTtl ?? _memoTtl);
    await _cache.put(key: key, type: 'tmdb_detail', payload: json);
  }

  /// Outils

  /// Permet de neutraliser la mémo courte (ex.: lors d’un hard refresh).
  void clearMemoryMemo() => _memo.clear();
}

/// LRU mémoire avec TTL par entrée.
class _LruMemo<K, V> {
  _LruMemo(this.capacity) : assert(capacity > 0);

  final int capacity;
  final Map<K, _MemoEntry<V>> _map = <K, _MemoEntry<V>>{};

  V? getIfFresh(K key) {
    final e = _map.remove(key);
    if (e == null) return null;
    if (DateTime.now().isAfter(e.expiresAt)) {
      return null; // expiré
    }
    // Réinsère pour marquer l’accès récent
    _map[key] = e;
    return e.value;
  }

  void put(K key, V value, {required Duration ttl}) {
    _map.remove(key);
    _map[key] = _MemoEntry(value, DateTime.now().add(ttl));
    // bornage
    while (_map.length > capacity) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}

class _MemoEntry<V> {
  _MemoEntry(this.value, this.expiresAt);
  final V value;
  final DateTime expiresAt;
}
