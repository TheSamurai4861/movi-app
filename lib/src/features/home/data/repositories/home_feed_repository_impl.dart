// ignore_for_file: public_member_api_docs

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';

import '../../../../core/state/app_state_controller.dart';
import '../../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../../shared/data/services/tmdb_cache_data_source.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../movie/data/datasources/tmdb_movie_remote_data_source.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../movie/domain/repositories/movie_repository.dart';
import '../../../tv/data/datasources/tmdb_tv_remote_data_source.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../tv/domain/repositories/tv_repository.dart';
import '../../domain/repositories/home_feed_repository.dart';
import '../../../../core/storage/services/cache_policy.dart';

/// Repository de flux Home.
/// Règles :
/// - Aucun pré-enrichissement réseau non initié par l’UI.
/// - Le Hero reste LITE ; l’UI peut déclencher du « full » ailleurs si besoin.
/// - Enrichissement on-demand : Cache → Réseau (LITE), idempotent par cycle d’écran.
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

  /// Garde d’idempotence pour l’enrichissement on-demand (par cycle d’écran).
  final Set<String> _enrichedIds = <String>{};

  /// Nombre max de pages "trending" parcourues pour construire le Hero.
  static const int _maxTrendingPages = 3;

  // ---------------------------------------------------------------------------
  // HERO (tendances → match IPTV → fallback VOD → fallback trending simple)
  // ---------------------------------------------------------------------------

  @override
  Future<List<MovieSummary>> getHeroMovies() async {
    final Set<int> availableTmdb = await _collectAvailableTmdbIds();

    // 1) Chercher des tendances TMDB qui matchent la playlist locale.
    List<dynamic> matchedDtos = <dynamic>[];
    for (var page = 1; page <= _maxTrendingPages; page++) {
      final List<dynamic> pageDtos = await _fetchTrendingMoviesPage(page);
      if (pageDtos.isEmpty) break;

      final List<dynamic> pageMatches = pageDtos
          .where(
            (dto) => (dto.posterPath != null) && availableTmdb.contains(dto.id),
          )
          .toList();

      if (pageMatches.isNotEmpty) {
        matchedDtos = pageMatches;
        break;
      }
    }

    // 2) Mapping (posters requis) et limitation.
    if (matchedDtos.isNotEmpty) {
      final List<MovieSummary> list = matchedDtos
          .map(_mapMovie)
          .whereType<MovieSummary>()
          .toList();
      if (list.isNotEmpty) {
        return list.length > 20 ? list.sublist(0, 20) : list;
      }
    }

    // 3) Fallback: utiliser le premier stream VOD dispo dans les playlists.
    final XtreamPlaylistItem? firstVod = await _pickFirstVodStream();
    if (firstVod != null) {
      final MovieSummary? synthetic = _fromPlaylistItemToMovieSummary(firstVod);
      if (synthetic != null) return <MovieSummary>[synthetic];
    }

    // 4) Ultime fallback: première page trending mappée (avec poster).
    final List<dynamic> fallbackDtos = await _fetchTrendingMoviesPage(1);
    final List<MovieSummary> fallbackList = fallbackDtos
        .map(_mapMovie)
        .whereType<MovieSummary>()
        .toList();
    return fallbackList.isNotEmpty
        ? (fallbackList.length > 20
              ? fallbackList.sublist(0, 20)
              : fallbackList)
        : <MovieSummary>[];
  }

  // ---------------------------------------------------------------------------
  // CONTINUE WATCHING
  // ---------------------------------------------------------------------------

  @override
  Future<List<MovieSummary>> getContinueWatchingMovies() {
    return _movieRepository.getContinueWatching();
  }

  @override
  Future<List<TvShowSummary>> getContinueWatchingShows() {
    return _tvRepository.getContinueWatching();
  }

  // ---------------------------------------------------------------------------
  // IPTV CATÉGORIES (LITE)
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, List<ContentReference>>> getIptvCategoryLists() async {
    final Map<String, List<ContentReference>> result =
        <String, List<ContentReference>>{};
    _enrichedIds.clear(); // Nouveau cycle d’écran.

    final List<XtreamAccountLite> accounts = await _safeGetAccounts();
    if (accounts.isEmpty) return result;

    for (final XtreamAccountLite account in accounts) {
      // Filtrage par sources actives si applicable.
      if (_appState.activeIptvSourceIds.isNotEmpty &&
          !_appState.activeIptvSourceIds.contains(account.id)) {
        continue;
      }

      final List<XtreamPlaylist> playlists = await _safeGetPlaylists(
        account.id,
      );

        for (final XtreamPlaylist pl in playlists) {
          final String visibleKey =
              '${account.alias}/${_cleanCategoryTitle(pl.title)}';

          // Construction LITE: aucun appel TMDB ici, l’UI déclenchera l’enrichissement.
          final List<ContentReference> items = <ContentReference>[];
          for (final XtreamPlaylistItem it in pl.items) {
            // IMPORTANT: ne jamais confondre streamId IPTV avec tmdbId.
            // Si tmdbId est absent, utiliser un identifiant non-numérique pour forcer
            // le fallback par titre côté enrichissement.
            final String refId = (it.tmdbId != null && it.tmdbId! > 0)
                ? it.tmdbId!.toString()
                : 'xtream:${it.streamId}';
            items.add(
              ContentReference(
              id: refId,
              title: MediaTitle(it.title),
              type: it.type == XtreamPlaylistItemType.series
                  ? ContentType.series
                  : ContentType.movie,
              poster: _safePosterUri(it.posterUrl),
              year: it.releaseYear,
              rating: it.rating,
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

  // ---------------------------------------------------------------------------
  // ENRICHISSEMENT à la demande (Cache → Réseau LITE)
  // ---------------------------------------------------------------------------

  @override
  Future<ContentReference> enrichReference(
    ContentReference ref, {
    CancelToken? cancelToken,
  }) async {
    int? idNum = int.tryParse(ref.id);
    final bool isSeries = ref.type == ContentType.series;

    // Idempotence: si déjà enrichi avec succès pendant ce cycle, renvoyer tel quel.
    if (_enrichedIds.contains(ref.id)) return ref;

    // Fallback titre → id si l'ID n’est pas numérique (souvent streamId IPTV).
    if (idNum == null) {
      try {
        if (isSeries) {
          final results = await _tvRemote.searchShows(ref.title.value, cancelToken: cancelToken);
          final match = results.isNotEmpty ? results.first : null;
          idNum = match?.id;
          if (kDebugMode) {
            debugPrint(
              '[HomeFeed] TV search fallback for "${ref.title.value}" → id=$idNum',
            );
          }
        } else {
          final results = await _moviesRemote.searchMovies(ref.title.value, cancelToken: cancelToken);
          final match = results.isNotEmpty ? results.first : null;
          idNum = match?.id;
          if (kDebugMode) {
            debugPrint(
              '[HomeFeed] MOVIE search fallback for "${ref.title.value}" → id=$idNum',
            );
          }
        }
      } catch (_) {
        // Ignorer les erreurs de recherche fallback.
      }
    }

    if (idNum == null) return ref;

    try {
      if (isSeries) {
        // TV: d’abord cache, sinon réseau LITE puis mise en cache.
        Map<String, dynamic>? cached = await _tmdbCache.getTvDetail(
          idNum,
          policyOverride: const CachePolicy(ttl: Duration(days: 3)),
        );
        if (cached == null) {
          final dto = await _tvRemote.fetchShowLite(idNum, cancelToken: cancelToken);
          final Map<String, dynamic> json = dto.toCache();
          await _tmdbCache.putTvDetail(idNum, json);
          cached = json;
        }
        final Map<String, dynamic> data = cached;

        final Map<String, dynamic> imagesMap =
            (data['images'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
        final List<dynamic> posters =
            (imagesMap['posters'] as List<dynamic>?) ?? const <dynamic>[];
        final String? posterPath =
            _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
        final String? tmdbTitle =
            (data['name']?.toString() ?? data['original_name']?.toString());

        final result = ContentReference(
          id: ref.id,
          title: MediaTitle(
            (tmdbTitle != null && tmdbTitle.isNotEmpty)
                ? tmdbTitle
                : ref.title.value,
          ),
          type: ref.type,
          // TMDB d’abord, sinon conserver le poster IPTV en fallback.
          poster: _images.poster(posterPath) ?? ref.poster, // w500 par défaut côté resolver
          year: _parseYear(data['first_air_date']?.toString()) ?? ref.year,
          rating: (data['vote_average'] as num?)?.toDouble() ?? ref.rating,
        );

        if (kDebugMode) {
          debugPrint(
            '[HomeFeed] Enriched TV id=${ref.id} year=${result.year} rating=${result.rating} posterPresent=${result.poster != null}',
          );
        }

        _enrichedIds.add(ref.id); // marquer après succès
        return result;
      } else {
        // Movie: d’abord cache, sinon réseau LITE puis mise en cache.
        Map<String, dynamic>? cached = await _tmdbCache.getMovieDetail(
          idNum,
          policyOverride: const CachePolicy(ttl: Duration(days: 3)),
        );
        if (cached == null) {
          final dto = await _moviesRemote.fetchMovieLite(idNum, cancelToken: cancelToken);
          final Map<String, dynamic> json = dto.toCache();
          await _tmdbCache.putMovieDetail(idNum, json);
          cached = json;
        }
        final Map<String, dynamic> data = cached;

        final Map<String, dynamic> imagesMap =
            (data['images'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
        final List<dynamic> posters =
            (imagesMap['posters'] as List<dynamic>?) ?? const <dynamic>[];
        final String? posterPath =
            _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
        final String? tmdbTitle =
            (data['title']?.toString() ?? data['original_title']?.toString());

        final result = ContentReference(
          id: ref.id,
          title: MediaTitle(
            (tmdbTitle != null && tmdbTitle.isNotEmpty)
                ? tmdbTitle
                : ref.title.value,
          ),
          type: ref.type,
          // TMDB d’abord, sinon conserver le poster IPTV en fallback.
          poster: _images.poster(posterPath) ?? ref.poster, // w500 par défaut côté resolver
          year: _parseYear(data['release_date']?.toString()) ?? ref.year,
          rating: (data['vote_average'] as num?)?.toDouble() ?? ref.rating,
        );

        if (kDebugMode) {
          debugPrint(
            '[HomeFeed] Enriched MOVIE id=${ref.id} year=${result.year} rating=${result.rating} posterPresent=${result.poster != null}',
          );
        }

        _enrichedIds.add(ref.id); // marquer après succès
        return result;
      }
    } catch (e) {
      // Défensif : conserver la carte existante en cas d’erreur réseau/parsing.
      assert(() {
        debugPrint('[HomeFeedRepositoryImpl] enrichReference error: $e');
        return true;
      }());
      // Ne pas marquer comme enrichi en cas d’échec, pour permettre un nouvel essai.
      return ref;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers HERO / mapping
  // ---------------------------------------------------------------------------

  Future<Set<int>> _collectAvailableTmdbIds() async {
    try {
      final Set<int> ids = await _iptvLocal.getAvailableTmdbIds();
      return ids;
    } catch (_) {
      // Fallback: reconstitution via accounts/playlists si l'API dédiée n’est pas disponible.
      final List<XtreamAccountLite> accs = await _safeGetAccounts();
      final Set<int> set = <int>{};
      for (final XtreamAccountLite acc in accs) {
        final List<XtreamPlaylist> pls = await _safeGetPlaylists(acc.id);
        for (final XtreamPlaylist pl in pls) {
          for (final XtreamPlaylistItem it in pl.items) {
            final int? id = it.tmdbId;
            if (id != null) set.add(id);
          }
        }
      }
      return set;
    }
  }

  Future<XtreamPlaylistItem?> _pickFirstVodStream() async {
    final List<XtreamAccountLite> accs = await _safeGetAccounts();
    if (accs.isEmpty) return null;

    for (final XtreamAccountLite acc in accs) {
      // Films d’abord, puis séries.
      final List<XtreamPlaylist> pls = await _safeGetPlaylists(acc.id);
      final List<XtreamPlaylist> moviesFirst = <XtreamPlaylist>[
        ...pls.where((p) => p.type == XtreamPlaylistType.movies),
        ...pls.where((p) => p.type == XtreamPlaylistType.series),
      ];
      for (final XtreamPlaylist pl in moviesFirst) {
        if (pl.items.isNotEmpty) return pl.items.first;
      }
    }
    return null;
  }

  MovieSummary? _fromPlaylistItemToMovieSummary(XtreamPlaylistItem item) {
    final Uri? poster = _safePosterUri(item.posterUrl);
    if (poster == null) return null;

    return MovieSummary(
      id: MovieId((item.tmdbId ?? item.streamId).toString()),
      tmdbId: item.tmdbId,
      title: MediaTitle(item.title),
      poster: poster,
      backdrop: poster, // Fallback si pas de backdrop dédié.
      releaseYear: item.releaseYear,
    );
  }

  MovieSummary? _mapMovie(dynamic dto) {
    final Uri? poster = _images.poster(dto.posterPath); // w500 par défaut
    if (poster == null) return null;
    return MovieSummary(
      id: MovieId(dto.id.toString()),
      tmdbId: dto.id as int?,
      title: MediaTitle(dto.title as String),
      poster: poster,
      backdrop: _images.backdrop(dto.backdropPath), // w780 par défaut
      releaseYear: _parseYear(dto.releaseDate as String?),
    );
  }

  /// Vérifie et filtre les URLs de posters IPTV (autorise http/https sans blacklist d'hôtes).
  Uri? _safePosterUri(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final Uri? u = Uri.tryParse(raw);
    if (u == null) return null;
    final String scheme = u.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return u;
  }

  String _cleanCategoryTitle(String raw) {
    // Ex: "premium-ott.com/Action" -> "Action"
    final int idx = raw.indexOf('/');
    if (idx >= 0 && idx < raw.length - 1) {
      return raw.substring(idx + 1);
    }
    return raw;
  }

  String? _selectPosterNoLang(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final List<Map<String, dynamic>> list = posters
        .cast<Map<String, dynamic>>();

    final List<Map<String, dynamic>> noLang =
        list.where((m) => m['iso_639_1'] == null).toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final List<Map<String, dynamic>> en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }

  // ---------------------------------------------------------------------------
  // Safe wrappers (résilients)
  // ---------------------------------------------------------------------------

  /// Version légère de compte pour itération UI (id/alias uniquement).
  Future<List<XtreamAccountLite>> _safeGetAccounts() async {
    try {
      final accounts = await _iptvLocal.getAccounts();
      // Projection minimale (évite d’exposer tout l’objet si lourd)
      return accounts
          .map((a) => XtreamAccountLite(id: a.id, alias: a.alias))
          .toList(growable: false);
    } catch (e) {
      assert(() {
        debugPrint('[HomeFeedRepositoryImpl] getAccounts error: $e');
        return true;
      }());
      return const <XtreamAccountLite>[];
    }
  }

  Future<List<XtreamPlaylist>> _safeGetPlaylists(String accountId) async {
    try {
      final List<XtreamPlaylist> playlists = await _iptvLocal.getPlaylists(
        accountId,
      );
      return playlists;
    } catch (e) {
      assert(() {
        debugPrint('[HomeFeedRepositoryImpl] getPlaylists error: $e');
        return true;
      }());
      return const <XtreamPlaylist>[];
    }
  }

  Future<List<dynamic>> _fetchTrendingMoviesPage(int page) async {
    try {
      final List<dynamic> res = await _moviesRemote.fetchTrendingMovies(
        window: 'week',
        page: page,
      );
      return res;
    } catch (e) {
      assert(() {
        debugPrint(
          '[HomeFeedRepositoryImpl] fetchTrendingMovies(page: $page) error: $e',
        );
        return true;
      }());
      // En cas d'échec > page 1 on coupe court ; pour page 1 on tente un dernier essai.
      if (page == 1) {
        try {
          final List<dynamic> res = await _moviesRemote.fetchTrendingMovies(
            window: 'week',
          );
          return res;
        } catch (_) {}
      }
      return const <dynamic>[];
    }
  }
}

/// Projection minimale d’un compte pour itération UI.
class XtreamAccountLite {
  const XtreamAccountLite({required this.id, required this.alias});
  final String id;
  final String alias;
}
