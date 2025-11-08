// lib/src/features/home/data/repositories/home_feed_repository_impl.dart
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';

import '../../../movie/domain/entities/movie_summary.dart';
import '../../../movie/domain/repositories/movie_repository.dart';
import '../../../movie/data/datasources/tmdb_movie_remote_data_source.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../tv/domain/repositories/tv_repository.dart';
import '../../../tv/data/datasources/tmdb_tv_remote_data_source.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../../core/state/app_state_controller.dart';
import '../../domain/repositories/home_feed_repository.dart';
import '../../../../shared/data/services/tmdb_cache_data_source.dart';

class HomeFeedRepositoryImpl implements HomeFeedRepository {
  HomeFeedRepositoryImpl(
    this._moviesRemote,
    this._tvRemote,
    this._iptvLocal,
    this._movieRepository,
    this._tvRepository,
    this._images,
    this._appState,
  ) : _tmdbCache = sl<TmdbCacheDataSource>();

  // Datasources / services
  final TmdbMovieRemoteDataSource _moviesRemote;
  final TmdbTvRemoteDataSource _tvRemote;
  final IptvLocalRepository _iptvLocal;
  final MovieRepository _movieRepository;
  final TvRepository _tvRepository;
  final TmdbImageResolver _images;
  final AppStateController _appState;
  final TmdbCacheDataSource _tmdbCache;

  // Limite de pré-chargement TMDB par catégorie
  static const int _preloadPerCategory = 5;

  // Nombre max de pages "tendances" à parcourir avant fallback playlist
  static const int _maxTrendingPages = 3;

  // ---------------------------
  // HERO (tendances → match IPTV → fallback premier stream VOD)
  // ---------------------------

  @override
  Future<List<MovieSummary>> getHeroMovies() async {
    // Ensemble des TMDB IDs présents dans la playlist (pour matcher rapidement)
    final availableTmdb = await _collectAvailableTmdbIds();

    // Parcours des pages de tendances
    List<dynamic> matchedDtos = [];
    for (int page = 1; page <= _maxTrendingPages; page++) {
      final trendingPage = await _fetchTrendingMoviesPage(page);
      if (trendingPage.isEmpty) break;

      final pageMatches = trendingPage
          .where((dto) => dto.posterPath != null && availableTmdb.contains(dto.id))
          .toList();
      if (pageMatches.isNotEmpty) {
        matchedDtos = pageMatches;
        break;
      }
    }

    // Si match → mappage + pre-cache Full pour le 1er héro
    if (matchedDtos.isNotEmpty) {
      final list = matchedDtos.map(_mapMovie).whereType<MovieSummary>().toList();
      if (list.isNotEmpty) {
        final first = list.first;
        if (first.tmdbId != null) {
          try {
            // Hero = DÉTAIL COMPLET (images/credits/reco)
            final detail = await _moviesRemote.fetchMovieFull(first.tmdbId!);
            await _tmdbCache.putMovieDetail(first.tmdbId!, detail.toCache());
          } catch (_) {/* no-op */}
        }
        return list.length > 20 ? list.sublist(0, 20) : list;
      }
    }

    // Fallback : aucun match → premier stream VOD de la/les playlists
    final firstVod = await _pickFirstVodStream();
    if (firstVod != null) {
      final synthetic = _fromPlaylistItemToMovieSummary(firstVod);
      if (synthetic != null) return [synthetic];
    }

    // Ultime garde-fou : revenir sur la première page Trending mappée
    final fallbackTrending = await _fetchTrendingMoviesPage(1);
    final fallbackList =
        fallbackTrending.map(_mapMovie).whereType<MovieSummary>().toList();
    return fallbackList.isNotEmpty
        ? (fallbackList.length > 20 ? fallbackList.sublist(0, 20) : fallbackList)
        : <MovieSummary>[];
  }

  // ---------------------------
  // CONTINUE WATCHING
  // ---------------------------

  @override
  Future<List<MovieSummary>> getContinueWatchingMovies() =>
      _movieRepository.getContinueWatching();

  @override
  Future<List<TvShowSummary>> getContinueWatchingShows() =>
      _tvRepository.getContinueWatching();

  // ---------------------------
  // IPTV CATÉGORIES (pré-charge 5, reste léger)
  // ---------------------------

  @override
  Future<Map<String, List<ContentReference>>> getIptvCategoryLists() async {
    final result = <String, List<ContentReference>>{};

    final accounts = await _safeGetAccounts();
    if (accounts.isEmpty) return result;

    for (final account in accounts) {
      if (_appState.activeIptvSourceIds.isNotEmpty &&
          !_appState.activeIptvSourceIds.contains(account.id)) {
        continue;
      }

      final playlists = await _safeGetPlaylists(account.id);
      for (final pl in playlists) {
        final visibleKey = '${account.alias}/${_cleanCategoryTitle(pl.title)}';

        // Pré-sélection des items avec tmdbId pour pré-enrichir les N premiers
        final withTmdbId = pl.items.where((i) => i.tmdbId != null).toList();
        final firstBatch = withTmdbId.take(_preloadPerCategory).toList();

        // 1) Pré-enrichir (films: réseau autorisé en Lite ; séries: désormais réseau autorisé aussi)
        final enriched = <ContentReference>[];
        for (final item in firstBatch) {
          final ref = await _enrichFirstBatchItem(item);
          if (ref != null) enriched.add(ref);
        }
        final enrichedById = {for (final r in enriched) r.id: r};

        // 2) Construire la liste finale dans l’ordre de la playlist
        final items = <ContentReference>[];
        for (final it in pl.items) {
          final keyId = (it.tmdbId ?? it.streamId).toString();
          final maybeEnriched = enrichedById[keyId];
          if (maybeEnriched != null) {
            items.add(maybeEnriched);
            continue;
          }
          items.add(
            ContentReference(
              id: keyId,
              title: MediaTitle(it.title),
              type: it.type == XtreamPlaylistItemType.series
                  ? ContentType.series
                  : ContentType.movie,
              poster: (it.posterUrl != null && it.posterUrl!.isNotEmpty)
                  ? Uri.tryParse(it.posterUrl!)
                  : null,
            ),
          );
        }

        if (items.isNotEmpty) {
          result[visibleKey] = items;
        }
      }
    }

    return result;
  }

  // ---------------------------
  // ENRICHISSEMENT "à la volée" d’un ContentReference léger (LITE)
  // ---------------------------

  @override
  Future<ContentReference> enrichReference(ContentReference ref) async {
    final idNum = int.tryParse(ref.id);
    if (idNum == null) return ref;

    Map<String, dynamic>? data;
    final isSeries = ref.type == ContentType.series;

    if (isSeries) {
      // TV: cache d'abord, puis réseau (LITE) si nécessaire
      data = await _tmdbCache.getTvDetail(idNum);
      if (data == null) {
        try {
          final dto = await _tvRemote.fetchShowLite(idNum);
          data = dto.toCache();
          await _tmdbCache.putTvDetail(idNum, data);
        } catch (_) {
          return ref;
        }
      }

      final images = (data['images'] as Map<String, dynamic>?) ?? const {};
      final posters = (images['posters'] as List<dynamic>? ?? const []);
      final posterPath =
          _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
      final tmdbTitle =
          (data['name']?.toString() ?? data['original_name']?.toString());

      return ContentReference(
        id: ref.id,
        title: MediaTitle(
          (tmdbTitle != null && tmdbTitle.isNotEmpty)
              ? tmdbTitle
              : ref.title.value,
        ),
        type: ref.type,
        poster: _images.poster(posterPath),
        year: _parseYear(data['first_air_date']?.toString()),
        rating: (data['vote_average'] as num?)?.toDouble(),
      );
    } else {
      // Movie: cache d'abord, puis réseau (LITE) si nécessaire
      data = await _tmdbCache.getMovieDetail(idNum);
      if (data == null) {
        try {
          final dto = await _moviesRemote.fetchMovieLite(idNum);
          data = dto.toCache();
          await _tmdbCache.putMovieDetail(idNum, data);
        } catch (_) {
          return ref;
        }
      }

      final images = (data['images'] as Map<String, dynamic>?) ?? const {};
      final posters = (images['posters'] as List<dynamic>? ?? const []);
      final posterPath =
          _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
      final tmdbTitle =
          (data['title']?.toString() ?? data['original_title']?.toString());

      return ContentReference(
        id: ref.id,
        title: MediaTitle(
          (tmdbTitle != null && tmdbTitle.isNotEmpty)
              ? tmdbTitle
              : ref.title.value,
        ),
        type: ref.type,
        poster: _images.poster(posterPath),
        year: _parseYear(data['release_date']?.toString()),
        rating: (data['vote_average'] as num?)?.toDouble(),
      );
    }
  }

  // ---------------------------
  // Helpers HERO / enrich / mapping
  // ---------------------------

  Future<Set<int>> _collectAvailableTmdbIds() async {
    try {
      final ids = await _iptvLocal.getAvailableTmdbIds();
      return ids.toSet();
    } catch (_) {
      // fallback : reconstituer via accounts/playlists
      final accs = await _safeGetAccounts();
      final set = <int>{};
      for (final acc in accs) {
        final pls = await _safeGetPlaylists(acc.id);
        for (final pl in pls) {
          for (final it in pl.items) {
            final id = it.tmdbId;
            if (id != null) set.add(id);
          }
        }
      }
      return set;
    }
  }

  Future<XtreamPlaylistItem?> _pickFirstVodStream() async {
    final accs = await _safeGetAccounts();
    if (accs.isEmpty) return null;

    for (final acc in accs) {
      // films d'abord, puis séries
      final pls = await _safeGetPlaylists(acc.id);
      final moviesFirst = [
        ...pls.where((p) => p.type == XtreamPlaylistType.movies),
        ...pls.where((p) => p.type == XtreamPlaylistType.series),
      ];
      for (final pl in moviesFirst) {
        if (pl.items.isNotEmpty) return pl.items.first;
      }
    }
    return null;
  }

  MovieSummary? _fromPlaylistItemToMovieSummary(XtreamPlaylistItem item) {
    final poster = (item.posterUrl != null && item.posterUrl!.isNotEmpty)
        ? Uri.tryParse(item.posterUrl!)
        : null;
    if (poster == null) return null;

    return MovieSummary(
      id: MovieId((item.tmdbId ?? item.streamId).toString()),
      tmdbId: item.tmdbId,
      title: MediaTitle(item.title),
      poster: poster,
      backdrop: poster, // fallback si pas de backdrop dédié
      releaseYear: item.releaseYear,
    );
  }

  Future<ContentReference?> _enrichFirstBatchItem(
    XtreamPlaylistItem item,
  ) async {
    final tmdbId = item.tmdbId;
    if (tmdbId == null) return null;

    Map<String, dynamic>? data;
    final isSeries = item.type == XtreamPlaylistItemType.series;

    if (isSeries) {
      // Séries : d'abord cache, puis réseau (LITE) si manquant — alignement avec films
      data = await _tmdbCache.getTvDetail(tmdbId);
      if (data == null) {
        try {
          final dto = await _tvRemote.fetchShowLite(tmdbId);
          data = dto.toCache();
          await _tmdbCache.putTvDetail(tmdbId, data);
        } catch (_) {/* no-op */}
      }
    } else {
      // Films : cache, puis réseau (LITE) si manquant
      data = await _tmdbCache.getMovieDetail(tmdbId);
      if (data == null) {
        try {
          final dto = await _moviesRemote.fetchMovieLite(tmdbId);
          data = dto.toCache();
          await _tmdbCache.putMovieDetail(tmdbId, data);
        } catch (_) {/* no-op */}
      }
    }

    Uri? posterUri;
    int? year;
    double? rating;
    String? tmdbTitle;

    if (data != null) {
      final images = (data['images'] as Map<String, dynamic>?) ?? const {};
      final posters = (images['posters'] as List<dynamic>? ?? const []);
      final posterPath =
          _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
      posterUri = _images.poster(posterPath);
      year = _parseYear(
        isSeries
            ? data['first_air_date']?.toString()
            : data['release_date']?.toString(),
      );
      rating = (data['vote_average'] as num?)?.toDouble();
      // Titre TMDB prioritaire
      tmdbTitle = isSeries
          ? (data['name']?.toString() ?? data['original_name']?.toString())
          : (data['title']?.toString() ?? data['original_title']?.toString());
    } else {
      posterUri = (item.posterUrl != null && item.posterUrl!.isNotEmpty)
          ? Uri.tryParse(item.posterUrl!)
          : null;
    }

    return ContentReference(
      id: tmdbId.toString(),
      title: MediaTitle(
        (tmdbTitle != null && tmdbTitle.isNotEmpty) ? tmdbTitle : item.title,
      ),
      type: isSeries ? ContentType.series : ContentType.movie,
      poster: posterUri,
      year: year,
      rating: rating,
    );
  }

  MovieSummary? _mapMovie(dynamic dto) {
    final poster = _images.poster(dto.posterPath);
    if (poster == null) return null;
    return MovieSummary(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id,
      title: MediaTitle(dto.title),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath),
      releaseYear: _parseYear(dto.releaseDate),
    );
  }

  String _cleanCategoryTitle(String raw) {
    // Ex: "premium-ott.com/Action" -> "Action"
    final idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      return raw.substring(idx + 1);
    }
    return raw;
  }

  String? _selectPosterNoLang(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = posters.cast<Map<String, dynamic>>();

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en = list
        .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
        .toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  int? _parseYear(String? raw) =>
      (raw != null && raw.isNotEmpty) ? int.tryParse(raw.substring(0, 4)) : null;

  // ---------------------------
  // Safe wrappers
  // ---------------------------

  Future<List<dynamic>> _safeGetAccounts() async {
    try {
      final accounts = await _iptvLocal.getAccounts();
      return accounts;
    } catch (_) {
      return const <dynamic>[];
    }
    }

  Future<List<dynamic>> _safeGetPlaylists(dynamic accountId) async {
    try {
      final playlists = await _iptvLocal.getPlaylists(accountId);
      return playlists;
    } catch (_) {
      return const <dynamic>[];
    }
  }

  Future<List<dynamic>> _fetchTrendingMoviesPage(int page) async {
    try {
      final dynamic any = _moviesRemote;
      final res = await any.fetchTrendingMovies(window: 'week', page: page);
      return res as List<dynamic>;
    } catch (_) {
      if (page == 1) {
        final res = await _moviesRemote.fetchTrendingMovies(window: 'week');
        return res;
      }
      return const <dynamic>[];
    }
  }
}
