import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/saga/data/dtos/tmdb_saga_detail_dto.dart';

class SagaLocalDataSource {
  SagaLocalDataSource(this._cacheRepository, this._localePreferences);

  final ContentCacheRepository _cacheRepository;
  final LocalePreferences _localePreferences;

  static const CachePolicy _detailPolicy = CachePolicy(ttl: Duration(days: 1));

  String get _locale => _localePreferences.languageCode;
  String _detailKey(int sagaId) => 'saga_detail_${_locale}_$sagaId';

  Future<void> saveSagaDetail(TmdbSagaDetailDto dto) {
    return _cacheRepository.put(
      key: _detailKey(dto.id),
      type: 'saga_detail',
      payload: dto.toCache(),
    );
  }

  Future<TmdbSagaDetailDto?> getSagaDetail(int sagaId) async {
    final cached = await _cacheRepository.getWithPolicy(
      _detailKey(sagaId),
      _detailPolicy,
    );
    if (cached == null) return null;
    return TmdbSagaDetailDto.fromCache(cached);
  }
}
