import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';

class TvLocalDataSource {
  TvLocalDataSource(this._cacheRepository, this._localePreferences);

  final ContentCacheRepository _cacheRepository;
  final LocalePreferences _localePreferences;
  static const CachePolicy _detailPolicy = CachePolicy(
    ttl: Duration(hours: 24),
  );
  static const CachePolicy _seasonPolicy = CachePolicy(
    ttl: Duration(hours: 12),
  );

  String get _locale => _localePreferences.languageCode;

  String _detailKey(int showId) => 'tv_detail_${_locale}_$showId';
  String _seasonKey(int showId, int seasonNumber) =>
      'tv_season_${_locale}_${showId}_$seasonNumber';

  Future<void> saveShowDetail(TmdbTvDetailDto dto) {
    return _cacheRepository.put(
      key: _detailKey(dto.id),
      type: 'tv_detail',
      payload: dto.toCache(),
    );
  }

  Future<TmdbTvDetailDto?> getShowDetail(int id) async {
    final cached = await _cacheRepository.getWithPolicy(
      _detailKey(id),
      _detailPolicy,
    );
    if (cached == null) return null;
    return TmdbTvDetailDto.fromCache(cached);
  }

  Future<void> saveSeason(
    int showId,
    int seasonNumber,
    TmdbTvSeasonDetailDto dto,
  ) {
    return _cacheRepository.put(
      key: _seasonKey(showId, seasonNumber),
      type: 'tv_season',
      payload: dto.toCache(),
    );
  }

  Future<TmdbTvSeasonDetailDto?> getSeason(int showId, int seasonNumber) async {
    final cached = await _cacheRepository.getWithPolicy(
      _seasonKey(showId, seasonNumber),
      _seasonPolicy,
    );
    if (cached == null) return null;
    return TmdbTvSeasonDetailDto.fromCache(cached);
  }

  /// Supprime le cache des métadonnées d'une série.
  Future<void> clearShowDetail(int showId) async {
    await _cacheRepository.remove(_detailKey(showId));
  }
}
