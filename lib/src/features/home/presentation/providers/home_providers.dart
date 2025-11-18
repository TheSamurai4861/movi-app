// lib/src/features/home/presentation/providers/home_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_hero.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_continue_watching.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_iptv_sections.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';

class NavIndexController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) {
    if (index == state) return;
    state = index;
  }
}

final homeNavIndexProvider = NotifierProvider<NavIndexController, int>(
  NavIndexController.new,
);

class HomeHeroIndexController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) {
    final next = index < 0 ? 0 : index;
    if (next == state) return;
    state = next;
  }
}

final homeHeroIndexProvider = NotifierProvider<HomeHeroIndexController, int>(
  HomeHeroIndexController.new,
);

/// État immutable du Home.
class HomeState {
  const HomeState({
    this.hero = const <MovieSummary>[],
    this.cwMovies = const <MovieSummary>[],
    this.cwShows = const <TvShowSummary>[],
    this.iptvLists = const <String, List<ContentReference>>{},
    this.isLoading = false,
    this.isHeroEmpty = false,
    this.error,
  });

  final List<MovieSummary> hero;
  final List<MovieSummary> cwMovies;
  final List<TvShowSummary> cwShows;
  final Map<String, List<ContentReference>> iptvLists;
  final bool isLoading;
  final bool isHeroEmpty;
  final String? error;

  HomeState copyWith({
    List<MovieSummary>? hero,
    List<MovieSummary>? cwMovies,
    List<TvShowSummary>? cwShows,
    Map<String, List<ContentReference>>? iptvLists,
    bool? isLoading,
    bool? isHeroEmpty,
    String? error,
  }) {
    return HomeState(
      hero: hero ?? this.hero,
      cwMovies: cwMovies ?? this.cwMovies,
      cwShows: cwShows ?? this.cwShows,
      iptvLists: iptvLists ?? this.iptvLists,
      isLoading: isLoading ?? this.isLoading,
      isHeroEmpty: isHeroEmpty ?? this.isHeroEmpty,
      error: error ?? this.error,
    );
  }
}

/// Contrôleur Home avec enrichissement batché + annulation propre.
class HomeController extends Notifier<HomeState> {
  late final HomeFeedRepository _repo;
  late final LoadHomeHero _loadHero;
  late final LoadHomeContinueWatching _loadCw;
  late final LoadHomeIptvSections _loadIptv;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  HomeState build() {
    _repo = ref.watch(homeFeedRepositoryProvider);
    _loadHero = LoadHomeHero(_repo);
    _loadCw = LoadHomeContinueWatching(_repo);
    _loadIptv = LoadHomeIptvSections(_repo);
    if (_eventSub == null) {
      final bus = ref.watch(appEventBusProvider);
      _eventSub = bus.stream.listen((event) {
        if (event.type == AppEventType.iptvSynced) {
          unawaited(refresh());
        }
      });
      ref.onDispose(() {
        _eventSub?.cancel();
        _eventSub = null;
      });
    }
    return const HomeState();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    final heroF = _loadHero();
    final iptvF = _loadIptv();
    final moviesF = _loadCw.movies();
    final showsF = _loadCw.shows();
    final hero = await heroF;
    final iptv = await iptvF;
    final movies = await moviesF;
    final shows = await showsF;
    state = state.copyWith(
      hero: hero,
      cwMovies: movies,
      cwShows: shows,
      iptvLists: iptv,
      isLoading: false,
      isHeroEmpty: hero.isEmpty,
    );
  }

  Future<void> refresh() => load();
}

final homeFeedRepositoryProvider = Provider<HomeFeedRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<HomeFeedRepository>();
});

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

/// Modèle pour représenter un média en cours avec ses informations de progression
class InProgressMedia {
  const InProgressMedia({
    required this.contentId,
    required this.type,
    required this.title,
    this.poster,
    this.backdrop,
    required this.progress,
    this.season,
    this.episode,
    this.year,
    this.duration,
    this.rating,
    this.seriesTitle,
    this.episodeTitle,
  });

  final String contentId;
  final ContentType type;
  final String title;
  final Uri? poster;
  final Uri? backdrop;
  final double progress; // 0.0 à 1.0
  final int? season;
  final int? episode;
  final int? year;
  final Duration? duration;
  final double? rating;
  final String? seriesTitle; // Pour les épisodes
  final String? episodeTitle; // Titre de l'épisode sans numéro
}

/// Provider pour charger les médias en cours depuis l'historique
final homeInProgressProvider = FutureProvider<List<InProgressMedia>>((ref) async {
  final historyRepo = ref.watch(slProvider)<HistoryLocalRepository>();
  
  final movies = await historyRepo.readAll(ContentType.movie);
  final shows = await historyRepo.readAll(ContentType.series);
  
  final allEntries = [...movies, ...shows];
  
  final inProgress = <InProgressMedia>[];
  
  for (final entry in allEntries) {
    final progress = _calculateProgress(entry);
    if (progress > 0 && progress < 0.9) {
      // Extraire le TMDB ID depuis contentId
      final tmdbId = _extractTmdbId(entry.contentId);
      
      Uri? backdrop;
      int? year;
      Duration? duration;
      double? rating;
      String? seriesTitle;
      String? episodeTitle;
      
      if (tmdbId != null) {
        try {
          if (entry.type == ContentType.movie) {
            // Récupérer les métadonnées du film
            final movieRepo = ref.read(movieRepositoryProvider);
            final movie = await movieRepo.getMovie(MovieId(entry.contentId));
            backdrop = await _getBackdropWithNullLanguage(tmdbId, isMovie: true);
            backdrop ??= movie.backdrop;
            year = movie.releaseDate.year;
            duration = movie.duration;
            rating = movie.voteAverage;
          } else if (entry.type == ContentType.series) {
            // Récupérer les métadonnées de la série
            final tvRepo = ref.read(tvRepositoryProvider);
            final tvShow = await tvRepo.getShowLite(SeriesId(entry.contentId));
            backdrop = await _getBackdropWithNullLanguage(tmdbId, isMovie: false);
            backdrop ??= tvShow.backdrop;
            year = tvShow.firstAirDate?.year;
            rating = tvShow.voteAverage;
            seriesTitle = tvShow.title.display;
            
            // Pour les épisodes, récupérer la durée et le titre depuis l'épisode spécifique
            if (entry.season != null && entry.episode != null) {
              try {
                final seasons = await tvRepo.getSeasons(SeriesId(entry.contentId));
                final season = seasons.firstWhere(
                  (s) => s.seasonNumber == entry.season,
                  orElse: () => seasons.first,
                );
                final episode = season.episodes.firstWhere(
                  (e) => e.episodeNumber == entry.episode,
                  orElse: () => season.episodes.first,
                );
                duration = episode.runtime;
                episodeTitle = episode.title.display; // Titre de l'épisode sans numéro
              } catch (_) {
                // Ignorer si l'épisode n'est pas trouvé
              }
            }
          }
        } catch (_) {
          // Si la récupération échoue, utiliser les valeurs par défaut
          backdrop = entry.poster; // Fallback sur poster si backdrop n'est pas disponible
        }
      } else {
        // Si pas de TMDB ID, utiliser le poster comme fallback
        backdrop = entry.poster;
      }
      
      // Si backdrop n'est pas disponible, utiliser poster comme fallback
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
  }
  
  // Trier par date de dernière lecture (plus récent en premier)
  inProgress.sort((a, b) {
    final aEntry = allEntries.firstWhere((e) => e.contentId == a.contentId && e.type == a.type);
    final bEntry = allEntries.firstWhere((e) => e.contentId == b.contentId && e.type == b.type);
    return bEntry.lastPlayedAt.compareTo(aEntry.lastPlayedAt);
  });
  
  return inProgress;
});

int? _extractTmdbId(String contentId) {
  // Si contentId commence par "xtream:", extraire le TMDB ID depuis la playlist
  // Sinon, essayer de parser comme un TMDB ID direct
  if (contentId.startsWith('xtream:')) {
    // Pour les IDs Xtream, on ne peut pas extraire le TMDB ID directement
    // Il faudrait chercher dans les playlists, mais c'est trop coûteux ici
    return null;
  }
  return int.tryParse(contentId);
}

/// Récupère le backdrop avec langue null depuis l'API images TMDB
Future<Uri?> _getBackdropWithNullLanguage(int tmdbId, {required bool isMovie}) async {
  try {
    final tmdbClient = sl<TmdbClient>();
    final images = sl<TmdbImageResolver>();
    
    final jsonImages = await tmdbClient.getJson(
      isMovie ? 'movie/$tmdbId/images' : 'tv/$tmdbId/images',
      query: {'include_image_language': 'null'},
    );
    
    final backdrops = jsonImages['backdrops'] as List<dynamic>?;
    if (backdrops == null || backdrops.isEmpty) return null;
    
    // Sélectionner le backdrop avec iso_639_1 == null
    final noLangBackdrops = backdrops
        .whereType<Map<String, dynamic>>()
        .where((m) => m['iso_639_1'] == null)
        .toList();
    
    if (noLangBackdrops.isNotEmpty) {
      final backdropPath = noLangBackdrops.first['file_path']?.toString();
      if (backdropPath != null) {
        return images.backdrop(backdropPath, size: 'w780');
      }
    }
    
    // Fallback sur le premier backdrop disponible
    final firstBackdrop = backdrops.first as Map<String, dynamic>?;
    final backdropPath = firstBackdrop?['file_path']?.toString();
    if (backdropPath != null) {
      return images.backdrop(backdropPath, size: 'w780');
    }
    
    return null;
  } catch (_) {
    return null;
  }
}

double _calculateProgress(HistoryEntry entry) {
  if (entry.duration == null || entry.duration!.inSeconds <= 0) return 0;
  final pos = entry.lastPosition?.inSeconds ?? 0;
  return pos / entry.duration!.inSeconds;
}

/// Provider pour obtenir l'état de lecture d'un média spécifique
final mediaHistoryProvider = FutureProvider.family<HistoryEntry?, ({String contentId, ContentType type})>((ref, params) async {
  final historyRepo = ref.watch(slProvider)<HistoryLocalRepository>();
  final entries = await historyRepo.readAll(params.type);
  try {
    final entry = entries.firstWhere(
      (e) => e.contentId == params.contentId,
    );
    final progress = _calculateProgress(entry);
    if (progress > 0 && progress < 0.9) {
      return entry;
    }
  } catch (_) {
    // Entry not found
  }
  return null;
});
