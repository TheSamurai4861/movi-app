import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';

/// Local data source for Saga details with locale-aware caching.
///
/// Uses `LocalePreferences.languageCode` to bind cache entries to the current
/// UI language, ensuring coherent localized content. Cache key pattern:
/// `saga_detail_<locale>_<id>` with a TTL of 1 day.
class SagaLocalDataSource {
  SagaLocalDataSource(this._cacheRepository, this._localePreferences);

  final ContentCacheRepository _cacheRepository;
  final LocalePreferences _localePreferences;

  static const CachePolicy _detailPolicy = CachePolicy(ttl: Duration(days: 1));

  String get _locale => _localePreferences.languageCode;
  String _detailKey(int sagaId) => 'saga_detail_${_locale}_$sagaId';

  /// Persists a saga detail payload in the locale-bound cache.
  Future<void> saveSagaDetail(TmdbSagaDetailDto dto) {
    return _cacheRepository.put(
      key: _detailKey(dto.id),
      type: 'saga_detail',
      payload: dto.toCache(),
    );
  }

  /// Retrieves a saga detail payload from the cache using the current locale.
  /// Returns `null` when missing or expired per the configured [CachePolicy].
  Future<TmdbSagaDetailDto?> getSagaDetail(int sagaId) async {
    final cached = await _cacheRepository.getWithPolicy(
      _detailKey(sagaId),
      _detailPolicy,
    );
    if (cached == null) return null;
    return TmdbSagaDetailDto.fromCache(cached);
  }
}
