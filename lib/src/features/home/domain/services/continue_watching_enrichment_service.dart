import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/home/domain/entities/in_progress_media.dart';

/// Service d'enrichissement des entrées d'historique "en cours" avec
/// métadonnées TMDB (backdrops, année, durée, rating, titre d'épisode, etc.).
class ContinueWatchingEnrichmentService {
  ContinueWatchingEnrichmentService({
    required HistoryLocalRepository historyRepo,
    required MovieRepository movieRepository,
    required TvRepository tvRepository,
    required TmdbClient tmdbClient,
    required TmdbImageResolver images,
  }) : _historyRepo = historyRepo,
       _movieRepository = movieRepository,
       _tvRepository = tvRepository,
       _tmdbClient = tmdbClient,
       _images = images;

  final HistoryLocalRepository _historyRepo;
  final MovieRepository _movieRepository;
  final TvRepository _tvRepository;
  final TmdbClient _tmdbClient;
  final TmdbImageResolver _images;

  /// Charge et enrichit la liste des médias "en cours" à partir de l'historique.
  ///
  /// [minProgress] et [maxProgress] bornent la progression considérée comme
  /// "en cours" (ex: 5%–90%).
  Future<List<InProgressMedia>> loadInProgress({
    double minProgress = 0.05,
    double maxProgress = 0.9,
  }) async {
    final movies = await _historyRepo.readAll(ContentType.movie);
    final shows = await _historyRepo.readAll(ContentType.series);

    final allEntries = <HistoryEntry>[...movies, ...shows];

    final inProgress = <InProgressMedia>[];

    for (final entry in allEntries) {
      final progress = _calculateProgress(entry);
      if (progress < minProgress || progress >= maxProgress) continue;

      final int? tmdbId = _extractTmdbId(entry.contentId);

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
                final seasons = await _tvRepository.getSeasons(
                  SeriesId(entry.contentId),
                );
                final season = seasons.firstWhere(
                  (s) => s.seasonNumber == entry.season,
                  orElse: () => seasons.first,
                );
                final episode = season.episodes.firstWhere(
                  (e) => e.episodeNumber == entry.episode,
                  orElse: () => season.episodes.first,
                );
                duration = episode.runtime;
                episodeTitle = episode.title.display;
              } catch (_) {
                // Ignorer si l'épisode n'est pas trouvé.
              }
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
      return null;
    }
    return int.tryParse(contentId);
  }

  Future<Uri?> _getBackdropWithNullLanguage(
    int tmdbId, {
    required bool isMovie,
  }) async {
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
          return _images.backdrop(backdropPath, size: 'w780');
        }
      }

      final firstBackdrop = backdrops.first as Map<String, dynamic>?;
      final backdropPath = firstBackdrop?['file_path']?.toString();
      if (backdropPath != null) {
        return _images.backdrop(backdropPath, size: 'w780');
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
