// lib/src/features/tv/data/repositories/tv_repository_impl.dart
import 'dart:async';

import 'package:dio/dio.dart';

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

/// Implémentation du repository TV.
/// Stratégie:
/// - **Lite-first** pour les listes (popular/search via remote summaries)
/// - **Full-on-demand** pour la fiche (fetchShowFull + saisons)
/// - **Cache local** (TvLocalDataSource) pour show/season si disponible
/// - Mapping strict, images via [TmdbImageResolver]
class TvRepositoryImpl implements TvRepository {
  TvRepositoryImpl(
    this._remote,
    this._images,
    this._watchlist,
    this._local,
    this._continueWatching,
  );

  final TmdbTvRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final WatchlistLocalRepository _watchlist;
  final TvLocalDataSource _local;
  final ContinueWatchingLocalRepository _continueWatching;

  // Concurrence bornée pour le chargement des saisons (évite de spam TMDB)
  static const int _maxConcurrentSeasons = 4;

  @override
  Future<TvShow> getShow(SeriesId id) async {
    final int showId = int.parse(id.value);

    // 1) Détail complet (cache → réseau)
    final TmdbTvDetailDto detail = await _loadShowDtoFull(showId);

    // 2) Détails de saisons (cache → réseau) avec concurrence bornée
    final Map<int, TmdbTvSeasonDetailDto> seasonDetails =
        await _loadSeasonsBatched(showId, detail.seasons);

    // 3) Mapping
    return _mapShow(detail, seasonDetails);
  }

  @override
  Future<List<Season>> getSeasons(SeriesId id) async {
    final int showId = int.parse(id.value);
    final TmdbTvDetailDto detail = await _loadShowDtoFull(showId);
    final Map<int, TmdbTvSeasonDetailDto> seasonDetails =
        await _loadSeasonsBatched(showId, detail.seasons);
    return _mapSeasons(detail.seasons, seasonDetails);
  }

  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) async {
    final int showId = int.parse(id.value);
    final int seasonNumber = int.parse(seasonId.value);
    final TmdbTvSeasonDetailDto season = await _loadSeasonDto(
      showId,
      seasonNumber,
    );
    return _mapEpisodes(season);
  }

  @override
  Future<List<TvShowSummary>> getFeaturedShows() async {
    // Popular = payload léger (résumés) → parfait pour la Home
    final List<TmdbTvSummaryDto> popular = await _remote.fetchPopular();
    return popular
        .map(_mapSummary)
        .whereType<TvShowSummary>()
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> getUserWatchlist() async {
    final entries = await _watchlist.readAll(ContentType.series);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            tmdbId: int.tryParse(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
            backdrop: null,
            seasonCount: null,
            status: null,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> getContinueWatching() async {
    final entries = await _continueWatching.readAll(ContentType.series);
    return entries
        .where((e) => e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            tmdbId: int.tryParse(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
            backdrop: null,
            seasonCount: null,
            status: null,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TvShowSummary>> searchShows(String query) async {
    final List<TmdbTvSummaryDto> results = await _remote.searchShows(query);
    return results
        .map(_mapSummary)
        .whereType<TvShowSummary>()
        .toList(growable: false);
  }

  @override
  Future<bool> isInWatchlist(SeriesId id) =>
      _watchlist.exists(id.value, ContentType.series);

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

  // --------- Chargement & cache ---------

  Future<TmdbTvDetailDto> _loadShowDtoFull(int showId) async {
    // Essaye cache local (peut déjà contenir un "full")
    final cached = await _local.getShowDetail(showId);
    if (cached != null) {
      // Détection FULL sans getter: présence de champs append_to_response
      final bool hasFull =
          (cached.logoPath != null) ||
          cached.cast.isNotEmpty ||
          cached.recommendations.isNotEmpty;
      if (hasFull) return cached;
    }

    // Sinon, charge en "full" depuis TMDB
    final CancelToken token = CancelToken();
    final remote = await _remote.fetchShowFull(showId, cancelToken: token);

    // Sauvegarde (remplace/complète)
    await _local.saveShowDetail(remote);
    return remote;
  }

  Future<Map<int, TmdbTvSeasonDetailDto>> _loadSeasonsBatched(
    int showId,
    List<TmdbTvSeasonDto> seasons,
  ) async {
    // Trie par numéro et ignore les numéros négatifs (cas spéciaux)
    final filtered = seasons.where((s) => s.seasonNumber >= 0).toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    final results = <int, TmdbTvSeasonDetailDto>{};
    // Exécute par batches pour limiter la concurrence
    List<Future<void>> batch = [];
    for (final season in filtered) {
      batch.add(
        _loadSeasonDto(showId, season.seasonNumber).then((dto) {
          results[season.seasonNumber] = dto;
        }),
      );
      if (batch.length >= _maxConcurrentSeasons) {
        await Future.wait(batch);
        batch = [];
      }
    }
    if (batch.isNotEmpty) {
      await Future.wait(batch);
    }

    // Complète avec placeholders si manque
    for (final s in filtered) {
      results.putIfAbsent(s.seasonNumber, () => _emptySeasonDetail(s));
    }
    return results;
  }

  Future<TmdbTvSeasonDetailDto> _loadSeasonDto(
    int showId,
    int seasonNumber,
  ) async {
    final cached = await _local.getSeason(showId, seasonNumber);
    if (cached != null) return cached;

    final CancelToken token = CancelToken();
    final remote = await _remote.fetchSeason(
      showId,
      seasonNumber,
      cancelToken: token,
    );
    await _local.saveSeason(showId, seasonNumber, remote);
    return remote;
  }

  // --------- Mapping ---------

  TvShow _mapShow(
    TmdbTvDetailDto dto,
    Map<int, TmdbTvSeasonDetailDto> seasonDetails,
  ) {
    final poster = _images.poster(dto.posterPath, size: 'w342');
    if (poster == null) {
      // On évite un crash dur : valeur sûre minimale
      throw StateError('TV show ${dto.id} missing poster');
    }

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
      cast: dto.cast.take(10).map(_mapCast).toList(growable: false),
      creators: dto.creators
          .map(
            (c) => PersonSummary(
              id: PersonId(c.id.toString()),
              tmdbId: c.id,
              name: c.name,
            ),
          )
          .toList(growable: false),
      seasons: _mapSeasons(dto.seasons, seasonDetails),
    );
  }

  List<Season> _mapSeasons(
    List<TmdbTvSeasonDto> seasons,
    Map<int, TmdbTvSeasonDetailDto> details,
  ) {
    return seasons
        .map((season) {
          final detail =
              details[season.seasonNumber] ?? _emptySeasonDetail(season);
          return Season(
            id: SeasonId(season.seasonNumber.toString()),
            seasonNumber: season.seasonNumber,
            title: MediaTitle(season.name),
            overview: season.overview.isEmpty
                ? null
                : Synopsis(season.overview),
            poster: _images.poster(season.posterPath),
            episodes: _mapEpisodes(detail),
            airDate: _parseDate(season.airDate),
          );
        })
        .toList(growable: false);
  }

  List<Episode> _mapEpisodes(TmdbTvSeasonDetailDto detail) {
    return detail.episodes
        .map(
          (ep) => Episode(
            id: EpisodeId(ep.id.toString()),
            episodeNumber: ep.episodeNumber,
            title: MediaTitle(ep.name),
            overview: ep.overview.isEmpty ? null : Synopsis(ep.overview),
            runtime: ep.runtime != null ? Duration(minutes: ep.runtime!) : null,
            airDate: _parseDate(ep.airDate),
            still: _images.still(ep.stillPath),
          ),
        )
        .toList(growable: false);
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
    // NOTE: si besoin, on pourrait enrichir rapidement seasonCount/status
    // via un hit "lite" mais ce n’est pas requis pour la Home.
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

  DateTime? _parseDate(String? date) =>
      (date == null || date.isEmpty) ? null : DateTime.tryParse(date);

  SeriesStatus? _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'ended':
        return SeriesStatus.ended;
      case 'returning series':
      case 'in production':
        return SeriesStatus.ongoing;
      case 'canceled':
        return SeriesStatus.hiatus;
      default:
        return null;
    }
  }

  // Heuristique simple basée sur la note TMDB → catégorisation locale
  ContentRating? _mapRating(double? voteAverage) {
    if (voteAverage == null) return null;
    if (voteAverage >= 8.0) return ContentRating.pg13;
    if (voteAverage >= 5.0) return ContentRating.pg;
    return ContentRating.unrated;
  }
}
