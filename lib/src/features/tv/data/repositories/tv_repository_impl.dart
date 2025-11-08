import '../../domain/entities/tv_show.dart';
import '../../domain/repositories/tv_repository.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../../shared/domain/entities/person_summary.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../../shared/domain/value_objects/synopsis.dart';
import '../../../../shared/domain/value_objects/content_rating.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../../../core/storage/repositories/watchlist_local_repository.dart';
import '../../../../core/storage/repositories/continue_watching_local_repository.dart';
import '../datasources/tmdb_tv_remote_data_source.dart';
import '../datasources/tv_local_data_source.dart';
import '../dtos/tmdb_tv_detail_dto.dart';
import '../dtos/tmdb_tv_season_detail_dto.dart';

class TvRepositoryImpl implements TvRepository {
  TvRepositoryImpl(this._remote, this._images, this._watchlist, this._local, this._continueWatching);

  final TmdbTvRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final WatchlistLocalRepository _watchlist;
  final TvLocalDataSource _local;
  final ContinueWatchingLocalRepository _continueWatching;

  @override
  Future<TvShow> getShow(SeriesId id) async {
    final showId = int.parse(id.value);
    final dto = await _loadShowDto(showId);
    final seasonDetails = await _loadSeasons(showId, dto.seasons);
    return _mapShow(dto, seasonDetails);
  }

  @override
  Future<List<Season>> getSeasons(SeriesId id) async {
    final showId = int.parse(id.value);
    final dto = await _loadShowDto(showId);
    final seasonDetails = await _loadSeasons(showId, dto.seasons);
    return _mapSeasons(dto.seasons, seasonDetails);
  }

  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) async {
    final seasonNumber = int.parse(seasonId.value);
    final season = await _loadSeasonDto(int.parse(id.value), seasonNumber);
    return _mapEpisodes(season);
  }

  @override
  Future<List<TvShowSummary>> getFeaturedShows() async {
    final popular = await _remote.fetchPopular();
    return popular.map(_mapSummary).whereType<TvShowSummary>().toList();
  }

  @override
  Future<List<TvShowSummary>> getUserWatchlist() async {
    final entries = await _watchlist.readAll(ContentType.series);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
          ),
        )
        .toList();
  }

  @override
  Future<List<TvShowSummary>> getContinueWatching() async {
    final entries = await _continueWatching.readAll(ContentType.series);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
          ),
        )
        .toList();
  }

  @override
  Future<List<TvShowSummary>> searchShows(String query) async {
    final results = await _remote.searchShows(query);
    return results.map(_mapSummary).whereType<TvShowSummary>().toList();
  }

  @override
  Future<bool> isInWatchlist(SeriesId id) async => _watchlist.exists(id.value, ContentType.series);

  @override
  Future<void> setWatchlist(SeriesId id, {required bool saved}) async {
    if (saved) {
      final show = await getShow(id);
      await _watchlist.upsert(
        WatchlistEntry(
          contentId: id.value,
          type: ContentType.series,
          title: show.title.value,
          poster: show.poster,
          addedAt: DateTime.now(),
        ),
      );
    } else {
      await _watchlist.remove(id.value, ContentType.series);
    }
  }

  Future<TmdbTvDetailDto> _loadShowDto(int showId) async {
    final cached = await _local.getShowDetail(showId);
    if (cached != null) return cached;
    final remote = await _remote.fetchShow(showId);
    await _local.saveShowDetail(remote);
    return remote;
  }

  Future<Map<int, TmdbTvSeasonDetailDto>> _loadSeasons(int showId, List<TmdbTvSeasonDto> seasons) async {
    final entries = await Future.wait(
      seasons.map(
        (season) async => MapEntry(
          season.seasonNumber,
          await _loadSeasonDto(showId, season.seasonNumber),
        ),
      ),
    );
    return Map<int, TmdbTvSeasonDetailDto>.fromEntries(entries);
  }

  Future<TmdbTvSeasonDetailDto> _loadSeasonDto(int showId, int seasonNumber) async {
    final cached = await _local.getSeason(showId, seasonNumber);
    if (cached != null) return cached;
    final remote = await _remote.fetchSeason(showId, seasonNumber);
    await _local.saveSeason(showId, seasonNumber, remote);
    return remote;
  }

  TvShow _mapShow(TmdbTvDetailDto dto, Map<int, TmdbTvSeasonDetailDto> seasonDetails) {
    final poster = _images.poster(dto.posterPath, size: 'w342');
    if (poster == null) throw StateError('TV show ${dto.id} missing poster');
    return TvShow(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      synopsis: Synopsis(dto.overview),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      firstAirDate: _parseDate(dto.firstAirDate),
      lastAirDate: _parseDate(dto.lastAirDate),
      status: _mapStatus(dto.status),
      rating: _mapRating(dto.voteAverage),
      genres: dto.genres,
      cast: dto.cast.take(10).map(_mapCast).toList(),
      creators: dto.creators.map((c) => PersonSummary(id: PersonId(c.id.toString()), tmdbId: c.id, name: c.name)).toList(),
      seasons: _mapSeasons(dto.seasons, seasonDetails),
    );
  }

  List<Season> _mapSeasons(List<TmdbTvSeasonDto> seasons, Map<int, TmdbTvSeasonDetailDto> details) {
    return seasons.map((season) {
      final detail = details[season.seasonNumber] ?? _emptySeasonDetail(season);
      return Season(
        id: SeasonId(season.seasonNumber.toString()),
        seasonNumber: season.seasonNumber,
        title: MediaTitle(season.name),
        overview: season.overview.isEmpty ? null : Synopsis(season.overview),
        poster: _images.poster(season.posterPath),
        episodes: _mapEpisodes(detail),
        airDate: _parseDate(season.airDate),
      );
    }).toList();
  }

  List<Episode> _mapEpisodes(TmdbTvSeasonDetailDto detail) {
    return detail.episodes
        .map(
          (episode) => Episode(
            id: EpisodeId(episode.id.toString()),
            episodeNumber: episode.episodeNumber,
            title: MediaTitle(episode.name),
            overview: episode.overview.isEmpty ? null : Synopsis(episode.overview),
            runtime: episode.runtime != null ? Duration(minutes: episode.runtime!) : null,
            airDate: _parseDate(episode.airDate),
            still: _images.still(episode.stillPath),
          ),
        )
        .toList();
  }

  TmdbTvSeasonDetailDto _emptySeasonDetail(TmdbTvSeasonDto season) {
    return TmdbTvSeasonDetailDto(
      id: season.id,
      name: season.name,
      airDate: season.airDate,
      episodes: const [],
    );
  }

  TvShowSummary? _mapSummary(TmdbTvSummaryDto dto) {
    final poster = _images.poster(dto.posterPath, size: 'w342');
    if (poster == null) return null;
    return TvShowSummary(
      id: SeriesId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.name),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      seasonCount: null,
      status: null,
    );
  }

  PersonSummary _mapCast(TmdbTvCastDto cast) {
    return PersonSummary(
      id: PersonId(cast.id.toString()),
      tmdbId: cast.id,
      name: cast.name,
      role: cast.character,
      photo: _images.poster(cast.profilePath),
    );
  }

  DateTime? _parseDate(String? date) => date == null || date.isEmpty ? null : DateTime.tryParse(date);

  SeriesStatus? _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'ended':
        return SeriesStatus.ended;
      case 'returning series':
      case 'in production':
        return SeriesStatus.ongoing;
      case 'canceled':
        return SeriesStatus.hiatus;
    }
    return null;
  }

  ContentRating? _mapRating(double? voteAverage) {
    if (voteAverage == null) return null;
    if (voteAverage >= 8.0) return ContentRating.pg13;
    if (voteAverage >= 5.0) return ContentRating.pg;
    return ContentRating.unrated;
  }
}
