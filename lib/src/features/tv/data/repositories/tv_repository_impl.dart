// lib/src/features/tv/data/repositories/tv_repository_impl.dart
import 'dart:async';

import 'package:dio/dio.dart';

import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/domain/value_objects/content_rating.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/di/di.dart';

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
    this._appState, {
    String? userId,
  }) : _userId = userId ?? 'default';

  final TmdbTvRemoteDataSource _remote;
  final TmdbImageResolver _images;
  final WatchlistLocalRepository _watchlist;
  final TvLocalDataSource _local;
  final ContinueWatchingLocalRepository _continueWatching;
  final AppStateController _appState;
  final String _userId;

  // Concurrence bornée pour le chargement des saisons (évite de spam TMDB)
  static const int _maxConcurrentSeasons = 4;

  /// Code de langue basé sur la locale courante (`fr-FR`, `en-US`, ou `en`).
  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  /// Extrait l'ID numérique d'un SeriesId, gérant les formats "xtream:ID" et "ID".
  int _extractNumericId(SeriesId id) {
    final value = id.value;
    if (value.startsWith('xtream:')) {
      return int.parse(value.substring(7));
    }
    return int.parse(value);
  }

  @override
  Future<TvShow> getShow(SeriesId id) async {
    final logger = sl<AppLogger>();
    final int showId = _extractNumericId(id);
    logger.debug(
      '📺 [REPO] getShow() démarré pour showId=$showId',
      category: 'tv_repository',
    );

    // 1) Détail complet (cache → réseau)
    logger.debug(
      '📺 [REPO] Chargement détail complet pour showId=$showId...',
      category: 'tv_repository',
    );
    final detailStartTime = DateTime.now();
    final TmdbTvDetailDto detail = await _loadShowDtoFull(showId);
    final detailDuration = DateTime.now().difference(detailStartTime);
    logger.debug(
      '📺 [REPO] Détail complet chargé pour showId=$showId en ${detailDuration.inMilliseconds}ms (${detail.seasons.length} saisons)',
      category: 'tv_repository',
    );

    // 2) Détails de saisons (cache → réseau) avec concurrence bornée
    logger.debug(
      '📺 [REPO] Chargement détails saisons pour showId=$showId (${detail.seasons.length} saisons)...',
      category: 'tv_repository',
    );
    final seasonsStartTime = DateTime.now();
    final Map<int, TmdbTvSeasonDetailDto> seasonDetails =
        await _loadSeasonsBatched(showId, detail.seasons);
    final seasonsDuration = DateTime.now().difference(seasonsStartTime);
    logger.debug(
      '📺 [REPO] Détails saisons chargés pour showId=$showId en ${seasonsDuration.inMilliseconds}ms (${seasonDetails.length} saisons)',
      category: 'tv_repository',
    );

    // 3) Mapping
    logger.debug(
      '📺 [REPO] Mapping pour showId=$showId...',
      category: 'tv_repository',
    );
    final result = _mapShow(detail, seasonDetails);
    logger.debug(
      '📺 [REPO] getShow() terminé pour showId=$showId',
      category: 'tv_repository',
    );
    return result;
  }

  @override
  Future<TvShow> getShowLite(SeriesId id) async {
    final int showId = _extractNumericId(id);

    // 1) Détail complet (cache → réseau)
    final TmdbTvDetailDto detail = await _loadShowDtoFull(showId);

    // 2) Mapping avec saisons vides (sans épisodes)
    return _mapShowLite(detail);
  }

  @override
  Future<List<Season>> getSeasons(SeriesId id) async {
    final int showId = _extractNumericId(id);
    final TmdbTvDetailDto detail = await _loadShowDtoFull(showId);
    final Map<int, TmdbTvSeasonDetailDto> seasonDetails =
        await _loadSeasonsBatched(showId, detail.seasons);
    return _mapSeasons(detail.seasons, seasonDetails);
  }

  @override
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId) async {
    final int showId = _extractNumericId(id);
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
    final List<TmdbTvSummaryDto> popular = await _remote.fetchPopular(
      language: _languageCode,
    );
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
    final List<TmdbTvSummaryDto> results = await _remote.searchShows(
      query,
      language: _languageCode,
    );
    return results
        .map(_mapSummary)
        .whereType<TvShowSummary>()
        .toList(growable: false);
  }

  @override
  Future<bool> isInWatchlist(SeriesId id) =>
      _watchlist.exists(id.value, ContentType.series, userId: _userId);

  @override
  Future<void> refreshMetadata(SeriesId id) async {
    final int showId = _extractNumericId(id);
    await _local.clearShowDetail(showId);
  }

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
          userId: _userId,
        ),
      );
    } else {
      await _watchlist.remove(id.value, ContentType.series, userId: _userId);
    }
  }

  // --------- Chargement & cache ---------

  Future<TmdbTvDetailDto> _loadShowDtoFull(int showId) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '📺 [REPO] _loadShowDtoFull() démarré pour showId=$showId',
      category: 'tv_repository',
    );

    // Essaye cache local (peut déjà contenir un "full")
    logger.debug(
      '📺 [REPO] Vérification cache local pour showId=$showId...',
      category: 'tv_repository',
    );
    final cacheStartTime = DateTime.now();
    final cached = await _local.getShowDetail(showId);
    final cacheDuration = DateTime.now().difference(cacheStartTime);
    logger.debug(
      '📺 [REPO] Cache local vérifié pour showId=$showId en ${cacheDuration.inMilliseconds}ms (cached=${cached != null})',
      category: 'tv_repository',
    );

    if (cached != null) {
      // Détection FULL sans getter: présence de champs append_to_response
      final bool hasFull =
          (cached.logoPath != null) ||
          cached.cast.isNotEmpty ||
          cached.recommendations.isNotEmpty;
      if (hasFull) {
        logger.debug(
          '📺 [REPO] Cache FULL trouvé pour showId=$showId, retour immédiat',
          category: 'tv_repository',
        );
        return cached;
      }
      logger.debug(
        '📺 [REPO] Cache PARTIEL trouvé pour showId=$showId, chargement depuis TMDB nécessaire',
        category: 'tv_repository',
      );
    } else {
      logger.debug(
        '📺 [REPO] Aucun cache trouvé pour showId=$showId, chargement depuis TMDB',
        category: 'tv_repository',
      );
    }

    // Sinon, charge en "full" depuis TMDB
    logger.debug(
      '📺 [REPO] Appel _remote.fetchShowFull() pour showId=$showId, language=${_appState.preferredLocale}...',
      category: 'tv_repository',
    );
    final remoteStartTime = DateTime.now();
    final CancelToken token = CancelToken();
    logger.debug(
      '📺 [REPO] Début attente fetchShowFull avec timeout 10s pour showId=$showId...',
      category: 'tv_repository',
    );
    try {
      // Annuler le token immédiatement en cas de timeout pour libérer la queue
      final remote = await _remote
          .fetchShowFull(showId, language: _languageCode, cancelToken: token)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              final elapsed = DateTime.now().difference(remoteStartTime);
              logger.log(
                LogLevel.warn,
                '📺 [REPO] ⚠️ TIMEOUT lors de fetchShowFull pour showId=$showId après ${elapsed.inSeconds}s (timeout=10s), annulation requête',
                category: 'tv_repository',
              );
              // Annuler le token immédiatement pour libérer la queue NetworkExecutor
              if (!token.isCancelled) {
                token.cancel('Timeout après 10s');
              }
              throw TimeoutException('Timeout fetchShowFull après 10s');
            },
          );
      final remoteDuration = DateTime.now().difference(remoteStartTime);
      logger.debug(
        '📺 [REPO] fetchShowFull réussi pour showId=$showId en ${remoteDuration.inMilliseconds}ms',
        category: 'tv_repository',
      );

      // Sauvegarde (remplace/complète)
      logger.debug(
        '📺 [REPO] Sauvegarde cache pour showId=$showId...',
        category: 'tv_repository',
      );
      final saveStartTime = DateTime.now();
      await _local.saveShowDetail(remote);
      final saveDuration = DateTime.now().difference(saveStartTime);
      logger.debug(
        '📺 [REPO] Cache sauvegardé pour showId=$showId en ${saveDuration.inMilliseconds}ms',
        category: 'tv_repository',
      );
      logger.debug(
        '📺 [REPO] _loadShowDtoFull() terminé pour showId=$showId',
        category: 'tv_repository',
      );
      return remote;
    } on TimeoutException catch (e, st) {
      logger.log(
        LogLevel.warn,
        '📺 [REPO] Timeout dans _loadShowDtoFull pour showId=$showId: $e',
        category: 'tv_repository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      logger.log(
        LogLevel.warn,
        '📺 [REPO] Erreur dans _loadShowDtoFull pour showId=$showId: $e',
        category: 'tv_repository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<Map<int, TmdbTvSeasonDetailDto>> _loadSeasonsBatched(
    int showId,
    List<TmdbTvSeasonDto> seasons,
  ) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '📺 [REPO] _loadSeasonsBatched() démarré pour showId=$showId, ${seasons.length} saisons',
      category: 'tv_repository',
    );

    // Trie par numéro et ignore les numéros négatifs (cas spéciaux)
    final filtered = seasons.where((s) => s.seasonNumber >= 0).toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

    logger.debug(
      '📺 [REPO] ${filtered.length} saisons à charger pour showId=$showId (maxConcurrent=$_maxConcurrentSeasons)',
      category: 'tv_repository',
    );

    final results = <int, TmdbTvSeasonDetailDto>{};
    // Exécute par batches pour limiter la concurrence
    List<Future<void>> batch = [];
    int batchNumber = 0;
    int seasonIndex = 0;
    for (final season in filtered) {
      seasonIndex++;
      logger.debug(
        '📺 [REPO] Ajout saison ${season.seasonNumber} au batch pour showId=$showId ($seasonIndex/${filtered.length})',
        category: 'tv_repository',
      );
      batch.add(
        _loadSeasonDto(showId, season.seasonNumber)
            .then((dto) {
              results[season.seasonNumber] = dto;
              logger.debug(
                '📺 [REPO] Saison ${season.seasonNumber} chargée pour showId=$showId',
                category: 'tv_repository',
              );
            })
            .catchError((e, st) {
              logger.log(
                LogLevel.warn,
                '📺 [REPO] Erreur lors du chargement de la saison ${season.seasonNumber} pour showId=$showId: $e',
                category: 'tv_repository',
                error: e,
                stackTrace: st,
              );
            }),
      );
      if (batch.length >= _maxConcurrentSeasons) {
        batchNumber++;
        logger.debug(
          '📺 [REPO] Attente batch $batchNumber pour showId=$showId (${batch.length} saisons)',
          category: 'tv_repository',
        );
        final batchStartTime = DateTime.now();
        await Future.wait(batch);
        final batchDuration = DateTime.now().difference(batchStartTime);
        logger.debug(
          '📺 [REPO] Batch $batchNumber terminé pour showId=$showId en ${batchDuration.inMilliseconds}ms',
          category: 'tv_repository',
        );
        batch = [];
      }
    }
    if (batch.isNotEmpty) {
      batchNumber++;
      logger.debug(
        '📺 [REPO] Attente batch final $batchNumber pour showId=$showId (${batch.length} saisons)',
        category: 'tv_repository',
      );
      final batchStartTime = DateTime.now();
      await Future.wait(batch);
      final batchDuration = DateTime.now().difference(batchStartTime);
      logger.debug(
        '📺 [REPO] Batch final $batchNumber terminé pour showId=$showId en ${batchDuration.inMilliseconds}ms',
        category: 'tv_repository',
      );
    }

    // Complète avec placeholders si manque
    for (final s in filtered) {
      results.putIfAbsent(s.seasonNumber, () => _emptySeasonDetail(s));
    }
    logger.debug(
      '📺 [REPO] _loadSeasonsBatched() terminé pour showId=$showId, ${results.length} saisons chargées',
      category: 'tv_repository',
    );
    return results;
  }

  Future<TmdbTvSeasonDetailDto> _loadSeasonDto(
    int showId,
    int seasonNumber,
  ) async {
    final logger = sl<AppLogger>();
    logger.debug(
      '📺 [REPO] _loadSeasonDto() démarré pour showId=$showId, season=$seasonNumber',
      category: 'tv_repository',
    );

    logger.debug(
      '📺 [REPO] Vérification cache saison pour showId=$showId, season=$seasonNumber...',
      category: 'tv_repository',
    );
    final cached = await _local.getSeason(showId, seasonNumber);
    if (cached != null) {
      logger.debug(
        '📺 [REPO] Cache trouvé pour showId=$showId, season=$seasonNumber',
        category: 'tv_repository',
      );
      return cached;
    }

    logger.debug(
      '📺 [REPO] Appel _remote.fetchSeason() pour showId=$showId, season=$seasonNumber...',
      category: 'tv_repository',
    );
    final fetchStartTime = DateTime.now();
    final CancelToken token = CancelToken();
    try {
      final remote = await _remote
          .fetchSeason(
            showId,
            seasonNumber,
            language: _languageCode,
            cancelToken: token,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.log(
                LogLevel.warn,
                '📺 [REPO] Timeout lors de fetchSeason pour showId=$showId, season=$seasonNumber (15s)',
                category: 'tv_repository',
              );
              throw TimeoutException('Timeout fetchSeason après 15s');
            },
          );
      final fetchDuration = DateTime.now().difference(fetchStartTime);
      logger.debug(
        '📺 [REPO] fetchSeason réussi pour showId=$showId, season=$seasonNumber en ${fetchDuration.inMilliseconds}ms',
        category: 'tv_repository',
      );

      logger.debug(
        '📺 [REPO] Sauvegarde cache saison pour showId=$showId, season=$seasonNumber...',
        category: 'tv_repository',
      );
      await _local.saveSeason(showId, seasonNumber, remote);
      logger.debug(
        '📺 [REPO] _loadSeasonDto() terminé pour showId=$showId, season=$seasonNumber',
        category: 'tv_repository',
      );
      return remote;
    } on TimeoutException catch (e, st) {
      logger.log(
        LogLevel.warn,
        '📺 [REPO] Timeout dans _loadSeasonDto pour showId=$showId, season=$seasonNumber: $e',
        category: 'tv_repository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e, st) {
      logger.log(
        LogLevel.warn,
        '📺 [REPO] Erreur dans _loadSeasonDto pour showId=$showId, season=$seasonNumber: $e',
        category: 'tv_repository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // --------- Mapping ---------

  TvShow _mapShow(
    TmdbTvDetailDto dto,
    Map<int, TmdbTvSeasonDetailDto> seasonDetails,
  ) {
    final poster = _images.poster(dto.posterPath, size: 'w780');
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
      backdrop: _images.backdrop(dto.backdropPath, size: 'w1280'),
      firstAirDate: _parseDate(dto.firstAirDate),
      lastAirDate: _parseDate(dto.lastAirDate),
      status: _mapStatus(dto.status),
      rating: _mapRating(dto.voteAverage),
      voteAverage: dto.voteAverage,
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

  TvShow _mapShowLite(TmdbTvDetailDto dto) {
    final poster = _images.poster(dto.posterPath, size: 'w780');
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
      backdrop: _images.backdrop(dto.backdropPath, size: 'w1280'),
      firstAirDate: _parseDate(dto.firstAirDate),
      lastAirDate: _parseDate(dto.lastAirDate),
      status: _mapStatus(dto.status),
      rating: _mapRating(dto.voteAverage),
      voteAverage: dto.voteAverage,
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
      // Saisons sans épisodes (seront chargées progressivement)
      seasons: dto.seasons
          .where((s) => s.seasonNumber >= 0)
          .map(
            (season) => Season(
              id: SeasonId(season.seasonNumber.toString()),
              seasonNumber: season.seasonNumber,
              title: MediaTitle(season.name),
              overview: season.overview.isEmpty
                  ? null
                  : Synopsis(season.overview),
              poster: _images.poster(season.posterPath),
              episodes: const [], // Pas d'épisodes dans la version lite
              airDate: _parseDate(season.airDate),
            ),
          )
          .toList(growable: false),
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
            voteAverage: ep.voteAverage,
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
