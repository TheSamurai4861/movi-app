// ignore_for_file: public_member_api_docs

import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/services/tmdb_cache_store.dart';

/// Data source de cache pour les détails TMDB (films & séries).
/// Combine :
/// - une mémoïsation mémoire **LRU** à court terme (pour éviter les re-hits
///   réseau durant les rafales d’accès d’un même écran),
/// - une **persistance** via [ContentCacheRepository] (TTL étendu).
///
/// Contrats publics stables :
/// - `getMovieDetail`, `putMovieDetail`
/// - `getTvDetail`, `putTvDetail`
/// - `clearMemoryMemo`
///
/// Les méthodes retournent `Map<String, dynamic>?` afin de laisser les couches
/// supérieures mapper/valider/extraire les champs utiles.
///
/// ⚠️ Aucun parsing métier n’est réalisé ici : *responsabilité unique = cache*.
class TmdbCacheDataSource implements TmdbCacheStore {
  TmdbCacheDataSource(
    this._cache, {
    Duration memoTtl = const Duration(seconds: 45),
    int memoCapacity = 512,
  }) : assert(memoCapacity > 0),
       _memoTtl = memoTtl,
       _memo = _LruMemo<String, Map<String, dynamic>>(memoCapacity);

  final ContentCacheRepository _cache;

  /// TTL par défaut de la couche persistée (peut être surchargé à l’appel).
  static const CachePolicy detailPolicy = CachePolicy(ttl: Duration(days: 7));

  /// TTL de la mémo en mémoire (process).
  final Duration _memoTtl;

  /// Mémo LRU (clé → JSON), bornée et expirante.
  final _LruMemo<String, Map<String, dynamic>> _memo;

  // ---------------------------------------------------------------------------
  // Clés de cache
  // ---------------------------------------------------------------------------

  String _movieKey(int id, String language) =>
      'tmdb_movie_detail_${id}_$language';
  String _tvKey(int id, String language) => 'tmdb_tv_detail_${id}_$language';
  String _cwBackdropKey(int id, String type) => 'cw_backdrop_${id}_$type';

  // ---------------------------------------------------------------------------
  // MOVIE
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> getMovieDetail(
    int id, {
    required String language,
    Duration? memoTtl,
    CachePolicy? policyOverride,
  }) async {
    if (id <= 0) return null;
    final String key = _movieKey(id, language);

    // 1) Mémo mémoire (rapide, court-terme)
    final Map<String, dynamic>? memo = _memo.getIfFresh(key);
    if (memo != null) return memo;

    // 2) Cache persistant (long-terme)
    final dynamic data = await _cache.getWithPolicy(
      key,
      policyOverride ?? detailPolicy,
    );

    if (data is Map<String, dynamic>) {
      _memo.put(key, data, ttl: memoTtl ?? _memoTtl);
      return data;
    }

    // Donnée absente ou illisible → laisser la couche appelante décider du fallback.
    return null;
  }

  @override
  Future<void> putMovieDetail(
    int id,
    Map<String, dynamic> json, {
    required String language,
    Duration? memoTtl,
  }) async {
    if (id <= 0) return;
    final String key = _movieKey(id, language);
    // Écrit d’abord en mémo pour lecture immédiate post-écriture.
    _memo.put(key, json, ttl: memoTtl ?? _memoTtl);
    await _cache.put(key: key, type: 'tmdb_detail', payload: json);
  }

  // ---------------------------------------------------------------------------
  // TV
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> getTvDetail(
    int id, {
    required String language,
    Duration? memoTtl,
    CachePolicy? policyOverride,
  }) async {
    if (id <= 0) return null;
    final String key = _tvKey(id, language);

    final Map<String, dynamic>? memo = _memo.getIfFresh(key);
    if (memo != null) return memo;

    final dynamic data = await _cache.getWithPolicy(
      key,
      policyOverride ?? detailPolicy,
    );

    if (data is Map<String, dynamic>) {
      _memo.put(key, data, ttl: memoTtl ?? _memoTtl);
      return data;
    }

    return null;
  }

  @override
  Future<void> putTvDetail(
    int id,
    Map<String, dynamic> json, {
    required String language,
    Duration? memoTtl,
  }) async {
    if (id <= 0) return;
    final String key = _tvKey(id, language);
    _memo.put(key, json, ttl: memoTtl ?? _memoTtl);
    await _cache.put(key: key, type: 'tmdb_detail', payload: json);
  }

  // ---------------------------------------------------------------------------
  // Outils
  // ---------------------------------------------------------------------------

  /// Vide la mémo mémoire *uniquement* (n’affecte pas la persistance).
  @override
  void clearMemoryMemo() => _memo.clear();

  // ---------------------------------------------------------------------------
  // Continue Watching backdrops
  // ---------------------------------------------------------------------------

  Future<Uri?> getContinueWatchingBackdrop(
    int id, {
    required bool isMovie,
    Duration? memoTtl,
    CachePolicy? policyOverride,
  }) async {
    if (id <= 0) return null;
    final String key = _cwBackdropKey(id, isMovie ? 'movie' : 'tv');

    final Map<String, dynamic>? memo = _memo.getIfFresh(key);
    final Uri? memoUri = _parseBackdrop(memo);
    if (memoUri != null) return memoUri;

    final dynamic data = await _cache.getWithPolicy(
      key,
      policyOverride ?? detailPolicy,
    );
    final Uri? cached = _parseBackdrop(data);
    if (cached == null) return null;

    _memo.put(
      key,
      <String, dynamic>{'url': cached.toString()},
      ttl: memoTtl ?? _memoTtl,
    );
    return cached;
  }

  Future<void> putContinueWatchingBackdrop(
    int id,
    Uri url, {
    required bool isMovie,
    Duration? memoTtl,
  }) async {
    if (id <= 0) return;
    final String key = _cwBackdropKey(id, isMovie ? 'movie' : 'tv');
    final payload = <String, dynamic>{'url': url.toString()};
    _memo.put(key, payload, ttl: memoTtl ?? _memoTtl);
    await _cache.put(key: key, type: 'tmdb_cw_backdrop', payload: payload);
  }

  Uri? _parseBackdrop(dynamic data) {
    if (data is Map<String, dynamic>) {
      final raw = data['url'];
      if (raw is String && raw.trim().isNotEmpty) {
        return Uri.tryParse(raw);
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return Uri.tryParse(data);
    }
    return null;
  }
}

// ============================================================================
// LRU mémoire simple avec TTL par entrée
// ============================================================================

class _LruMemo<K, V> {
  _LruMemo(this.capacity) : assert(capacity > 0);

  final int capacity;
  final Map<K, _MemoEntry<V>> _map = <K, _MemoEntry<V>>{};

  /// Retourne la valeur si non expirée, en actualisant son ordre LRU.
  V? getIfFresh(K key) {
    final _MemoEntry<V>? removed = _map.remove(key);
    if (removed == null) return null;

    // Expiration
    if (DateTime.now().isAfter(removed.expiresAt)) {
      return null;
    }

    // Réinsère pour marquer l’accès récent
    _map[key] = removed;
    return removed.value;
  }

  /// Insère/actualise une valeur avec son TTL et applique le bornage LRU.
  void put(K key, V value, {required Duration ttl}) {
    _map.remove(key);
    _map[key] = _MemoEntry<V>(value, DateTime.now().add(ttl));

    // Bornage LRU (Map préserve l’ordre d’insertion → clé la plus ancienne = first)
    while (_map.length > capacity) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}

class _MemoEntry<V> {
  const _MemoEntry(this.value, this.expiresAt);
  final V value;
  final DateTime expiresAt;
}
