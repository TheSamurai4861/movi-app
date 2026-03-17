import 'package:movi/src/core/storage/services/cache_policy.dart';

/// Abstraction de cache pour les détails TMDB.
abstract class TmdbCacheStore {
  Future<Map<String, dynamic>?> getMovieDetail(
    int id, {
    required String language,
    Duration? memoTtl,
    CachePolicy? policyOverride,
  });

  Future<void> putMovieDetail(
    int id,
    Map<String, dynamic> json, {
    required String language,
    Duration? memoTtl,
  });

  Future<Map<String, dynamic>?> getTvDetail(
    int id, {
    required String language,
    Duration? memoTtl,
    CachePolicy? policyOverride,
  });

  Future<void> putTvDetail(
    int id,
    Map<String, dynamic> json, {
    required String language,
    Duration? memoTtl,
  });

  void clearMemoryMemo();
}
