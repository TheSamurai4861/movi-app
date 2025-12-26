import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/services/tmdb_image_selector_service.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';

/// Métadonnées enrichies pour un élément du carrousel Home Hero.
class HomeHeroMetadata {
  const HomeHeroMetadata({
    required this.isTv,
    this.posterBg,
    this.poster,
    this.backdrop,
    this.logo,
    this.title,
    this.overview,
    this.year,
    this.rating,
    this.runtimeMinutes,
  });

  final bool isTv;
  final String? posterBg;
  final String? poster;
  final String? backdrop;
  final String? logo;
  final String? title;
  final String? overview;
  final int? year;
  final double? rating;
  final int? runtimeMinutes;
}

/// Service responsable de charger et d'hydrater les métadonnées TMDB
/// nécessaires au carrousel Home Hero.
class HomeHeroMetadataService {
  HomeHeroMetadataService({
    required TmdbCacheDataSource cache,
    required TmdbImageResolver images,
    required TmdbMovieRemoteDataSource moviesRemote,
    required TmdbTvRemoteDataSource tvRemote,
    required AppStateController appState,
  })  : _cache = cache,
        _images = images,
        _moviesRemote = moviesRemote,
        _tvRemote = tvRemote,
        _appState = appState;

  final TmdbCacheDataSource _cache;
  final TmdbImageResolver _images;
  final TmdbMovieRemoteDataSource _moviesRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final AppStateController _appState;

  /// Code de langue basé sur la locale courante (`fr-FR`, `en-US`, ou `en`).
  String get _languageCode {
    final locale = _appState.preferredLocale;
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  /// Charge les métadonnées complètes pour un film du hero.
  ///
  /// Stratégie :
  /// 1. Tente de lire les détails film depuis le cache.
  /// 2. Si absent, tente les détails série depuis le cache.
  /// 3. Si toujours absent, fetch complet (film puis série en fallback)
  ///    et persistance dans le cache.
  /// 4. Construit un [HomeHeroMetadata] enrichi (poster, backdrop, logo, etc.).
  Future<HomeHeroMetadata?> loadMetadata(MovieSummary movie) async {
    final int? id = movie.tmdbId;
    if (id == null) return null;

    final String language = _languageCode;

    Map<String, dynamic>? data = await _safeGetMovieDetail(id, language);
    bool isTvData = false;

    if (data == null) {
      data = await _safeGetTvDetail(id, language);
      isTvData = data != null;
    }

    // Rien en cache → fetch complet puis relecture.
    if (data == null) {
      try {
        try {
          final dto = await _moviesRemote.fetchMovieFull(
            id,
            language: language,
          );
          final json = dto.toCache();
          await _cache.putMovieDetail(id, json, language: language);
          data = json;
          isTvData = false;
        } catch (_) {
          final dto = await _tvRemote.fetchShowFull(
            id,
            language: language,
          );
          final json = dto.toCache();
          await _cache.putTvDetail(id, json, language: language);
          data = json;
          isTvData = true;
        }
      } catch (_) {
        // En cas d'échec complet, abandonner proprement.
        return null;
      }
    }

    final Map<String, dynamic> images =
        (data['images'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final List<dynamic> posters =
        (images['posters'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> logos =
        (images['logos'] as List<dynamic>?) ?? const <dynamic>[];

    // Sélection centralisée : poster no-lang → en → best ; logo en → no-lang → best
    final String? posterPath =
        TmdbImageSelectorService.selectPosterPath(posters) ??
        data['poster_path']?.toString();
    final String? posterBgPath = data['poster_background']?.toString();
    final String? logoPath = TmdbImageSelectorService.selectLogoPath(logos);

    // Tailles standardisées pour stabilité/perf
    final Uri? posterUri = _images.poster(posterPath, size: 'w500');
    final Uri? posterBgUri = _images.poster(posterBgPath, size: 'w780');
    final Uri? backdropUri = _images.backdrop(
      data['backdrop_path']?.toString(),
      size: 'w780',
    );
    final Uri? logoUri = _images.logo(logoPath);

    final String overview = (data['overview']?.toString() ?? '').trim();
    final String? title = (data['title']?.toString() ?? '').trim().isEmpty
        ? null
        : data['title']?.toString();

    final double? vote = (data['vote_average'] is num)
        ? (data['vote_average'] as num).toDouble()
        : null;

    // Durée (film) / durée épisode (série)
    int? runtimeMinutes;
    final dynamic rawRuntime = data['runtime'];
    if (rawRuntime is int) {
      runtimeMinutes = rawRuntime;
    } else {
      final dynamic ert = data['episode_run_time'];
      if (ert is List && ert.isNotEmpty && ert.first is int) {
        runtimeMinutes = ert.first as int;
      }
    }

    // Année depuis release_date (film) ou first_air_date (série)
    final String? date =
        (data['release_date']?.toString().trim().isNotEmpty ?? false)
            ? data['release_date']?.toString()
            : data['first_air_date']?.toString();
    final int? year = _parseYear(date) ?? movie.releaseYear;

    return HomeHeroMetadata(
      isTv: isTvData,
      posterBg: posterBgUri?.toString(),
      poster: posterUri?.toString(),
      backdrop: backdropUri?.toString(),
      logo: logoUri?.toString(),
      title: title,
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
      runtimeMinutes: runtimeMinutes,
    );
  }

  Future<Map<String, dynamic>?> _safeGetMovieDetail(
    int id,
    String language,
  ) async {
    try {
      return await _cache.getMovieDetail(id, language: language);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetTvDetail(
    int id,
    String language,
  ) async {
    try {
      return await _cache.getTvDetail(id, language: language);
    } catch (_) {
      return null;
    }
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }
}
