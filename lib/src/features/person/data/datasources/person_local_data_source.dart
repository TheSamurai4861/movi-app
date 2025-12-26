import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';

class PersonLocalDataSource {
  PersonLocalDataSource(this._cacheRepository, this._localePreferences);

  final ContentCacheRepository _cacheRepository;
  final LocalePreferences _localePreferences;

  static const CachePolicy _detailPolicy = CachePolicy(ttl: Duration(days: 3));

  String get _locale => _localePreferences.languageCode;
  String _detailKey(int personId) => 'person_detail_${_locale}_$personId';

  Future<void> savePersonDetail(TmdbPersonDetailDto dto) {
    return _cacheRepository.put(
      key: _detailKey(dto.id),
      type: 'person_detail',
      payload: dto.toCache(),
    );
  }

  Future<TmdbPersonDetailDto?> getPersonDetail(int id) async {
    final cached = await _cacheRepository.getWithPolicy(
      _detailKey(id),
      _detailPolicy,
    );
    if (cached == null) return null;
    return TmdbPersonDetailDto.fromCache(cached);
  }
}
