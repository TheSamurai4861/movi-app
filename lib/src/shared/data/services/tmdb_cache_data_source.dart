import '../../../core/storage/repositories/content_cache_repository.dart';
import '../../../core/storage/services/cache_policy.dart';

class TmdbCacheDataSource {
  TmdbCacheDataSource(this._cache);

  final ContentCacheRepository _cache;

  // 7 jours de TTL pour les détails TMDB
  static const CachePolicy detailPolicy = CachePolicy(ttl: Duration(days: 7));

  String _movieKey(int id) => 'tmdb_movie_detail_$id';
  String _tvKey(int id) => 'tmdb_tv_detail_$id';

  Future<Map<String, dynamic>?> getMovieDetail(int id) =>
      _cache.getWithPolicy(_movieKey(id), detailPolicy);

  Future<Map<String, dynamic>?> getTvDetail(int id) =>
      _cache.getWithPolicy(_tvKey(id), detailPolicy);

  Future<void> putMovieDetail(int id, Map<String, dynamic> json) =>
      _cache.put(key: _movieKey(id), type: 'tmdb_detail', payload: json);

  Future<void> putTvDetail(int id, Map<String, dynamic> json) =>
      _cache.put(key: _tvKey(id), type: 'tmdb_detail', payload: json);
}
