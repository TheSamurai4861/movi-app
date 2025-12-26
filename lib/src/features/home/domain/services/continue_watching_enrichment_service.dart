import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/home/domain/entities/in_progress_media.dart';
import 'package:movi/src/core/preferences/preferences.dart';

/// Service d'enrichissement des entrées d'historique "en cours" avec
/// métadonnées TMDB (backdrops, année, durée, rating, titre d'épisode, etc.).
class ContinueWatchingEnrichmentService {
  ContinueWatchingEnrichmentService({
    required HistoryLocalRepository historyRepo,
    required MovieRepository movieRepository,
    required TvRepository tvRepository,
    required TmdbCacheDataSource tmdbCache,
    required TmdbClient tmdbClient,
    required TmdbImageResolver images,
    required XtreamLookupService xtreamLookup,
    required TmdbIdResolverService tmdbIdResolver,
    required LocalePreferences localePreferences,
  }) : _historyRepo = historyRepo,
       _movieRepository = movieRepository,
       _tvRepository = tvRepository,
       _tmdbCache = tmdbCache,
       _tmdbClient = tmdbClient,
       _images = images,
       _xtreamLookup = xtreamLookup,
       _tmdbIdResolver = tmdbIdResolver,
       _localePreferences = localePreferences;

  final HistoryLocalRepository _historyRepo;
  final MovieRepository _movieRepository;
  final TvRepository _tvRepository;
  final TmdbCacheDataSource _tmdbCache;
  final TmdbClient _tmdbClient;
  final TmdbImageResolver _images;
  final XtreamLookupService _xtreamLookup;
  final TmdbIdResolverService _tmdbIdResolver;
  final LocalePreferences _localePreferences;

  /// Charge et enrichit la liste des médias "en cours" à partir de l'historique.
  ///
  /// [minProgress] et [maxProgress] bornent la progression considérée comme
  /// "en cours" (ex: 5%–90%).
  Future<List<InProgressMedia>> loadInProgress({
    double minProgress = 0.05,
    double maxProgress = 0.9,
    String userId = 'default',
  }) async {
    final movies = await _historyRepo.readAll(ContentType.movie, userId: userId);
    final shows = await _historyRepo.readAll(ContentType.series, userId: userId);

    final allEntries = <HistoryEntry>[...movies, ...shows];

    final inProgress = <InProgressMedia>[];

    for (final entry in allEntries) {
      final progress = _calculateProgress(entry);
      if (progress < minProgress || progress >= maxProgress) continue;

      int? tmdbId = _extractTmdbId(entry.contentId);
      
      // Si pas de tmdbId et que c'est un ID Xtream, essayer de le trouver via recherche
      if (tmdbId == null && entry.contentId.startsWith('xtream:')) {
        tmdbId = await _searchTmdbIdForHistoryEntry(entry);
      }

      Uri? backdrop;
      int? year;
      Duration? duration;
      double? rating;
      String? seriesTitle;
      String? episodeTitle;

      if (tmdbId != null) {
        try {
          if (entry.type == ContentType.movie) {
            final movie = await _movieRepository.getMovie(
              MovieId(entry.contentId),
            );
            backdrop = await _getBackdropWithNullLanguage(
              tmdbId,
              isMovie: true,
            );
            backdrop ??= movie.backdrop;
            year = movie.releaseDate.year;
            duration = movie.duration;
            rating = movie.voteAverage;
          } else if (entry.type == ContentType.series) {
            final tvShow = await _tvRepository.getShowLite(
              SeriesId(entry.contentId),
            );
            backdrop = await _getBackdropWithNullLanguage(
              tmdbId,
              isMovie: false,
            );
            backdrop ??= tvShow.backdrop;
            year = tvShow.firstAirDate?.year;
            rating = tvShow.voteAverage;
            seriesTitle = tvShow.title.display;

            if (entry.season != null && entry.episode != null) {
              try {
                final episodes = await _tvRepository.getEpisodes(
                  SeriesId(entry.contentId),
                  SeasonId(entry.season!.toString()),
                );
                final episode = episodes.firstWhere(
                  (e) => e.episodeNumber == entry.episode,
                  orElse: () => episodes.first,
                );
                duration = episode.runtime;
                episodeTitle = episode.title.display;
              } catch (_) {}
            }
          }
        } catch (_) {
          // Si la récupération échoue, utiliser les valeurs par défaut.
          backdrop = entry.poster;
        }
      } else {
        // Si pas de TMDB ID, utiliser le poster comme fallback.
        backdrop = entry.poster;
      }

      // Si backdrop n'est pas disponible, utiliser poster comme fallback.
      backdrop ??= entry.poster;

      inProgress.add(
        InProgressMedia(
          contentId: entry.contentId,
          type: entry.type,
          title: entry.title,
          poster: entry.poster,
          backdrop: backdrop,
          progress: progress,
          season: entry.season,
          episode: entry.episode,
          year: year,
          duration: duration,
          rating: rating,
          seriesTitle: seriesTitle,
          episodeTitle: episodeTitle,
        ),
      );
    }

    // Trier par date de dernière lecture (plus récent en premier).
    inProgress.sort((a, b) {
      final aEntry = allEntries.firstWhere(
        (e) => e.contentId == a.contentId && e.type == a.type,
      );
      final bEntry = allEntries.firstWhere(
        (e) => e.contentId == b.contentId && e.type == b.type,
      );
      return bEntry.lastPlayedAt.compareTo(aEntry.lastPlayedAt);
    });

    return inProgress;
  }

  double _calculateProgress(HistoryEntry entry) {
    if (entry.duration == null || entry.duration!.inSeconds <= 0) return 0;
    final pos = entry.lastPosition?.inSeconds ?? 0;
    return pos / entry.duration!.inSeconds;
  }

  int? _extractTmdbId(String contentId) {
    if (contentId.startsWith('xtream:')) {
      // Pour les IDs Xtream, on ne peut pas extraire le TMDB ID directement.
      // La recherche sera effectuée dans _searchTmdbIdForHistoryEntry
      return null;
    }
    return int.tryParse(contentId);
  }

  /// Recherche un tmdbId pour une entrée d'historique Xtream.
  ///
  /// Utilise XtreamLookupService pour obtenir l'item Xtream complet,
  /// puis TmdbIdResolverService pour rechercher le tmdbId par titre.
  Future<int?> _searchTmdbIdForHistoryEntry(HistoryEntry entry) async {
    try {
      // Obtenir l'item Xtream complet si possible
      final expectedType = entry.type == ContentType.movie
          ? XtreamPlaylistItemType.movie
          : entry.type == ContentType.series
          ? XtreamPlaylistItemType.series
          : null;
      final xtreamItem = await _xtreamLookup.findItemByMovieId(
        entry.contentId,
        expectedType: expectedType,
      );
      
      if (xtreamItem != null) {
        // Si l'item a déjà un tmdbId, l'utiliser
        if (xtreamItem.tmdbId != null) {
          return xtreamItem.tmdbId;
        }
        
        // Sinon, rechercher par titre
        final language = _localePreferences.languageCode;
        return await _tmdbIdResolver.enhancedSearchTmdbId(
          item: xtreamItem,
          language: language,
        );
      }
      
      // Si on ne peut pas obtenir l'item Xtream, essayer quand même une recherche par titre
      // en utilisant le titre de l'entrée d'historique
      final language = _localePreferences.languageCode;
      if (entry.type == ContentType.movie) {
        return await _tmdbIdResolver.searchTmdbIdByTitleForMovie(
          title: entry.title,
          releaseYear: null, // On n'a pas l'année dans HistoryEntry
          language: language,
        );
      } else if (entry.type == ContentType.series) {
        return await _tmdbIdResolver.searchTmdbIdByTitleForTv(
          title: entry.title,
          releaseYear: null, // On n'a pas l'année dans HistoryEntry
          language: language,
        );
      }
      
      return null;
    } catch (_) {
      // En cas d'erreur, retourner null pour utiliser le fallback poster
      return null;
    }
  }

  Future<Uri?> _getBackdropWithNullLanguage(
    int tmdbId, {
    required bool isMovie,
  }) async {
    try {
      final cached = await _tmdbCache.getContinueWatchingBackdrop(
        tmdbId,
        isMovie: isMovie,
      );
      if (cached != null) {
        _logBackdropCache(
          action: 'hit',
          tmdbId: tmdbId,
          isMovie: isMovie,
        );
        return cached;
      }
      _logBackdropCache(
        action: 'miss',
        tmdbId: tmdbId,
        isMovie: isMovie,
      );
    } catch (_) {}

    try {
      final jsonImages = await _tmdbClient.getJson(
        isMovie ? 'movie/$tmdbId/images' : 'tv/$tmdbId/images',
        query: {'include_image_language': 'null'},
      );

      final backdrops = jsonImages['backdrops'] as List<dynamic>?;
      if (backdrops == null || backdrops.isEmpty) return null;

      final noLangBackdrops = backdrops
          .whereType<Map<String, dynamic>>()
          .where((m) => m['iso_639_1'] == null)
          .toList();

      if (noLangBackdrops.isNotEmpty) {
        final backdropPath = noLangBackdrops.first['file_path']?.toString();
        if (backdropPath != null) {
          final backdrop = _images.backdrop(backdropPath, size: 'w780');
          if (backdrop != null) {
            await _tmdbCache.putContinueWatchingBackdrop(
              tmdbId,
              backdrop,
              isMovie: isMovie,
            );
          }
          return backdrop;
        }
      }

      final firstBackdrop = backdrops.first as Map<String, dynamic>?;
      final backdropPath = firstBackdrop?['file_path']?.toString();
      if (backdropPath != null) {
        final backdrop = _images.backdrop(backdropPath, size: 'w780');
        if (backdrop != null) {
          await _tmdbCache.putContinueWatchingBackdrop(
            tmdbId,
            backdrop,
            isMovie: isMovie,
          );
        }
        return backdrop;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  void _logBackdropCache({
    required String action,
    required int tmdbId,
    required bool isMovie,
  }) {
    final ts = DateTime.now().toIso8601String();
    final type = isMovie ? 'movie' : 'tv';
    unawaited(
      LoggingService.log(
        '[CwBackdropCache] ts=$ts id=$tmdbId type=$type action=$action',
      ),
    );
  }
}
