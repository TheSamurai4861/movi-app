// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';

import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';

import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;

/// Carrousel du Hero d’accueil.
/// - Affiche une liste de films/séries en rotation automatique.
/// - Lit d’abord le cache, puis hydrate si nécessaire (cache → full fetch).
/// - Sélection d’images centralisée pour éliminer les posters avec texte.
class HomeHeroCarousel extends ConsumerStatefulWidget {
  const HomeHeroCarousel({super.key, required this.movies});

  final List<MovieSummary> movies;

  @override
  ConsumerState<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

final _tmdbCacheProvider = Provider<TmdbCacheDataSource>(
  (ref) => ref.watch(slProvider)<TmdbCacheDataSource>(),
);
final _tmdbImagesProvider = Provider<TmdbImageResolver>(
  (ref) => ref.watch(slProvider)<TmdbImageResolver>(),
);
final _tmdbMovieRemoteProvider = Provider<TmdbMovieRemoteDataSource>(
  (ref) => ref.watch(slProvider)<TmdbMovieRemoteDataSource>(),
);
final _tmdbTvRemoteProvider = Provider<TmdbTvRemoteDataSource>(
  (ref) => ref.watch(slProvider)<TmdbTvRemoteDataSource>(),
);

class _HomeHeroCarouselState extends ConsumerState<HomeHeroCarousel>
    with WidgetsBindingObserver {
  // Mise en page
  static const double _totalHeight = 590;
  static const double _overlayHeight = 150;

  // Limite de décodage (px @device) pour soulager CPU/GPU en desktop
  static const int _maxHeroCachePx = 1440;

  // Timings
  static const Duration _rotation = Duration(seconds: 9);
  static const Duration _fade = Duration(milliseconds: 800);
  static const double _synopsisHeight = 80;

  // DI
  late final TmdbCacheDataSource _cache;
  late final TmdbImageResolver _images;
  late final TmdbMovieRemoteDataSource _moviesRemote;
  late final TmdbTvRemoteDataSource _tvRemote;

  final ValueNotifier<bool> _favorite = ValueNotifier<bool>(false);

  // États
  final Set<int> _hydratedIds = <int>{};
  final Set<int> _fullyHydratedIds = <int>{};
  final Map<int, Future<_HeroMeta?>> _metaFutures = <int, Future<_HeroMeta?>>{};

  int _index = 0;
  Timer? _timer;
  bool _backdropNotified = false;

  @override
  void initState() {
    super.initState();
    _cache = ref.read(_tmdbCacheProvider);
    _images = ref.read(_tmdbImagesProvider);
    _moviesRemote = ref.read(_tmdbMovieRemoteProvider);
    _tvRemote = ref.read(_tmdbTvRemoteProvider);
    WidgetsBinding.instance.addObserver(this);
    final persistedIndex = ref.read(hp.homeHeroIndexProvider);
    if (persistedIndex > 0 && persistedIndex < widget.movies.length) {
      _index = persistedIndex;
    }
    _prepareCurrentMeta();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.movies, widget.movies)) {
      final persistedIndex = ref.read(hp.homeHeroIndexProvider);
      final int maxIndex = (widget.movies.length - 1);
      _index = (persistedIndex < 0)
          ? 0
          : (persistedIndex > maxIndex ? maxIndex : persistedIndex);
      _metaFutures.clear();
      _backdropNotified = false;
      _prepareCurrentMeta();
      _restartTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _favorite.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Lifecycle : pause/reprise du timer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restartTimer();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  // ---------------------------------------------------------------------------
  // Rotation / préparation
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    if (widget.movies.length <= 1) return;
    _timer = Timer.periodic(_rotation, (_) {
      if (!mounted) return;
      _triggerNext();
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  void _triggerNext() {
    final int len = widget.movies.length;
    if (len <= 1) return;
    setState(() {
      _index = (_index + 1) % len;
      _backdropNotified = false;
    });
    ref.read(hp.homeHeroIndexProvider.notifier).set(_index);
    _prepareCurrentMeta();
  }

  void _prepareCurrentMeta() {
    final MovieSummary? m = _currentMovie;
    if (m == null || m.tmdbId == null) return;

    // Préparer meta courante (cache→affichage)
    _metaFutures[m.tmdbId!] ??= _loadMeta(m);
    if (_index == 0) {
      _hydrateMetaIfNeeded(m);
    }

    // Précharger image courante
    _precacheBgFor(m, isNext: false);

    // Préparer meta suivante pour une transition fluide
    final MovieSummary? next = _nextMovie;
    if (next?.tmdbId != null) {
      _metaFutures[next!.tmdbId!] ??= _loadMeta(next);
      if (!_fullyHydratedIds.contains(next.tmdbId!)) {
        _hydrateMetaFull(next);
      }
      _precacheBgFor(next, isNext: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de données / cache
  // ---------------------------------------------------------------------------

  MovieSummary? get _currentMovie =>
      (widget.movies.isNotEmpty ? widget.movies[_index] : null);

  MovieSummary? get _nextMovie => widget.movies.isNotEmpty
      ? widget.movies[(_index + 1) % widget.movies.length]
      : null;

  Future<_HeroMeta?> _loadMeta(MovieSummary m) async {
    final int? id = m.tmdbId;
    if (id == null) return null;

    // 1) Film en cache, sinon 2) Série en cache
    Map<String, dynamic>? data = await _safeGetMovieDetail(id);
    bool isTvData = false;
    if (data == null) {
      data = await _safeGetTvDetail(id);
      isTvData = data != null;
    }
    if (data == null) return null;

    final Map<String, dynamic> images =
        (data['images'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final List<dynamic> posters =
        (images['posters'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> logos =
        (images['logos'] as List<dynamic>?) ?? const <dynamic>[];

    // Sélection centralisée : poster no-lang → en → best ; logo en → no-lang → best
    final String? posterPath =
        _ImageSelector.selectPoster(posters) ?? data['poster_path']?.toString();
    final String? posterBgPath = data['poster_background']?.toString();
    final String? logoPath = _ImageSelector.selectLogo(logos);

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
    final int? year = _parseYear(date) ?? m.releaseYear;

    return _HeroMeta(
      isTv: isTvData,
      posterBg: posterBgUri?.toString(),
      poster: posterUri?.toString(),
      backdrop: backdropUri?.toString(),
      logo: logoUri?.toString(),
      title: title,
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
      runtime: runtimeMinutes,
    );
  }

  Future<void> _hydrateMetaIfNeeded(MovieSummary m) async {
    final int? id = m.tmdbId;
    if (id == null || _hydratedIds.contains(id)) return;

    Map<String, dynamic>? data = await _safeGetMovieDetail(id);
    bool isTvData = false;
    if (data == null) {
      data = await _safeGetTvDetail(id);
      isTvData = data != null;
    }

    // Aucune donnée en cache → fetch FULL immédiat
    if (data == null) {
      try {
        _hydratedIds.add(id);
        try {
          final dto = await _moviesRemote.fetchMovieFull(
            id,
            language: ref.read(currentLanguageCodeProvider),
          );
          await _cache.putMovieDetail(
            id,
            dto.toCache(),
            language: ref.read(currentLanguageCodeProvider),
          );
          _fullyHydratedIds.add(id);
        } catch (_) {
          final dto = await _tvRemote.fetchShowFull(
            id,
            language: ref.read(currentLanguageCodeProvider),
          );
          await _cache.putTvDetail(
            id,
            dto.toCache(),
            language: ref.read(currentLanguageCodeProvider),
          );
          _fullyHydratedIds.add(id);
        }
        if (!mounted) return;
        _metaFutures[id] = _loadMeta(m);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            'HomeHeroCarousel: hydration (no cache) failed for $id: $e\n$st',
          );
        }
      }
      return;
    }

    // Cache présent mais incomplet → hydrate si nécessaire
    final Map<String, dynamic> images =
        (data['images'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final List<dynamic> posters =
        (images['posters'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> logos =
        (images['logos'] as List<dynamic>?) ?? const <dynamic>[];
    final String overview = (data['overview']?.toString() ?? '').trim();
    final double? vote = (data['vote_average'] is num)
        ? (data['vote_average'] as num).toDouble()
        : null;
    final bool hasRuntime =
        data['runtime'] is int ||
        (data['episode_run_time'] is List &&
            (data['episode_run_time'] as List).isNotEmpty);

    final bool needsHydration =
        posters.isEmpty ||
        logos.isEmpty ||
        overview.isEmpty ||
        vote == null ||
        !hasRuntime;
    if (!needsHydration) return;

    try {
      _hydratedIds.add(id);
      if (!isTvData) {
        final dto = await _moviesRemote.fetchMovieFull(
          id,
          language: ref.read(currentLanguageCodeProvider),
        );
        await _cache.putMovieDetail(
          id,
          dto.toCache(),
          language: ref.read(currentLanguageCodeProvider),
        );
        _fullyHydratedIds.add(id);
      } else {
        final dto = await _tvRemote.fetchShowFull(
          id,
          language: ref.read(currentLanguageCodeProvider),
        );
        await _cache.putTvDetail(
          id,
          dto.toCache(),
          language: ref.read(currentLanguageCodeProvider),
        );
        _fullyHydratedIds.add(id);
      }
      if (!mounted) return;
      _metaFutures[id] = _loadMeta(m);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: hydration failed for $id: $e\n$st');
      }
    }
  }

  Future<void> _hydrateMetaFull(MovieSummary m) async {
    final int? id = m.tmdbId;
    if (id == null ||
        _hydratedIds.contains(id) ||
        _fullyHydratedIds.contains(id)) {
      return;
    }
    try {
      _hydratedIds.add(id);
      try {
        final dto = await _moviesRemote.fetchMovieFull(
          id,
          language: ref.read(currentLanguageCodeProvider),
        );
        await _cache.putMovieDetail(
          id,
          dto.toCache(),
          language: ref.read(currentLanguageCodeProvider),
        );
      } catch (_) {
        final dto = await _tvRemote.fetchShowFull(
          id,
          language: ref.read(currentLanguageCodeProvider),
        );
        await _cache.putTvDetail(
          id,
          dto.toCache(),
          language: ref.read(currentLanguageCodeProvider),
        );
      }
      _fullyHydratedIds.add(id);
      if (!mounted) return;
      _metaFutures[id] = _loadMeta(m);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: hydration full failed for $id: $e\n$st');
      }
    }
  }

  Future<Map<String, dynamic>?> _safeGetMovieDetail(int id) async {
    try {
      return await _cache.getMovieDetail(
        id,
        language: ref.read(currentLanguageCodeProvider),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: getMovieDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetTvDetail(int id) async {
    try {
      return await _cache.getTvDetail(
        id,
        language: ref.read(currentLanguageCodeProvider),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: getTvDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final MovieSummary? movie = _currentMovie;

    return SizedBox(
      height: _totalHeight,
      width: double.infinity,
      child: (widget.movies.isEmpty)
          ? const _HeroEmpty(overlayHeight: _overlayHeight)
          : movie == null
          ? const _HeroSkeleton(overlayHeight: _overlayHeight)
          : FutureBuilder<_HeroMeta?>(
              future: _metaFutures[movie.tmdbId!],
              builder: (context, snap) {
                final _HeroMeta? meta = snap.data;

                // Ordre de préférence du fond :
                // 1) Poster TMDB (no-lang → en → best)
                // 2) Poster playlist
                // 3) Backdrop TMDB
                // 4) Backdrop playlist
                final String? bgSrc =
                    _coerceHttpUrl(meta?.posterBg) ??
                    _coerceHttpUrl(meta?.poster) ??
                    _coerceHttpUrl(movie.poster.toString()) ??
                    _coerceHttpUrl(meta?.backdrop) ??
                    _coerceHttpUrl(movie.backdrop?.toString());

                final bool hasTitle = meta?.title?.isNotEmpty ?? false;

                final int? year = meta?.year ?? movie.releaseYear;
                final String yearText = (year ?? '—').toString();

                final double? rating = meta?.rating;
                final String? ratingText = (rating == null)
                    ? null
                    : (rating >= 10
                          ? rating.toStringAsFixed(0)
                          : rating.toStringAsFixed(1));

                final String? durationText = _formatDuration(meta?.runtime);
                final bool hasSynopsis = (meta?.overview?.isNotEmpty ?? false);

                Widget buildBackground() {
                  Widget image;
                  if (bgSrc != null) {
                    final mq = MediaQuery.of(context);
                    final int rawPx = (mq.size.width * mq.devicePixelRatio)
                        .round();
                    final int cacheWidth = rawPx.clamp(480, _maxHeroCachePx);
                    image = Image.network(
                      bgSrc,
                      key: ValueKey(bgSrc),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.0, -0.5),
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) {
                        if (!_backdropNotified) {
                          _backdropNotified = true;
                        }
                        return const ColoredBox(color: Color(0xFF222222));
                      },
                      frameBuilder: (context, child, frame, wasSync) {
                        if (frame != null && !_backdropNotified) {
                          _backdropNotified = true;
                        }
                        return child;
                      },
                    );
                  } else {
                    image = const ColoredBox(color: Color(0xFF222222));
                  }
                  return AnimatedSwitcher(
                    duration: _fade,
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: image,
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildBackground(),

                          // Overlay sombre animé (transition inter-slides)
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _GlobalOverlay(height: _totalHeight),
                          ),
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _BottomOverlay(height: _overlayHeight),
                          ),
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: _TopOverlay(height: _overlayHeight),
                          ),
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: _TopOverlay(height: _overlayHeight),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 150,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                  child: hasTitle
                                      ? AnimatedSwitcher(
                                          duration: _fade,
                                          transitionBuilder:
                                              (child, animation) =>
                                                  FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                          layoutBuilder: (current, previous) =>
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ...previous,
                                                  if (current != null) current,
                                                ],
                                              ),
                                          child: Text(
                                            meta!.title!,
                                            key: ValueKey(
                                              '${movie.tmdbId}_title',
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : AnimatedSwitcher(
                                          duration: _fade,
                                          transitionBuilder:
                                              (child, animation) =>
                                                  FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                          layoutBuilder: (current, previous) =>
                                              Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ...previous,
                                                  if (current != null) current,
                                                ],
                                              ),
                                          child: Text(
                                            movie.title.value,
                                            key: ValueKey(
                                              '${movie.tmdbId}_titleFallback',
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: _fade,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.center,
                        children: [...previous, if (current != null) current],
                      ),
                      child: Row(
                        key: ValueKey('${movie.tmdbId}_pills'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (durationText != null)
                            MoviPill(durationText, large: true),
                          if (durationText != null && year != null)
                            const SizedBox(width: 8),
                          if (year != null) MoviPill(yearText, large: true),
                          if (year != null && ratingText != null)
                            const SizedBox(width: 8),
                          if (ratingText != null)
                            MoviPill(ratingText, large: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: _synopsisHeight,
                      child: AnimatedSwitcher(
                        duration: _fade,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, if (current != null) current],
                        ),
                        child: hasSynopsis
                            ? Padding(
                                key: ValueKey('${movie.tmdbId}_synopsis'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Text(
                                  meta!.overview!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MoviPrimaryButton(
                              label: AppLocalizations.of(context)!.homeWatchNow,
                              assetIcon: AppAssets.iconPlay,
                              onPressed: () {
                                final m = _currentMovie;
                                if (m == null) return;
                                final media = MoviMedia(
                                  id: m.id.value,
                                  title: m.title.display,
                                  poster: m.backdrop ?? m.poster,
                                  year: m.releaseYear,
                                  type: MoviMediaType.movie,
                                );
                                context.push(AppRouteNames.movie, extra: media);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ValueListenableBuilder<bool>(
                            valueListenable: _favorite,
                            builder: (_, isFav, __) {
                              return MoviFavoriteButton(
                                isFavorite: isFav,
                                onPressed: () => _favorite.value = !isFav,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pré-chargement images
  // ---------------------------------------------------------------------------

  void _precacheBgFor(MovieSummary m, {required bool isNext}) {
    final int? id = m.tmdbId;
    if (id == null) return;

    final Future<_HeroMeta?>? future = _metaFutures[id];
    if (future == null) return;

    future.then((meta) async {
      if (!mounted) return;

      final bool ok = isNext
          ? (_nextMovie?.tmdbId == id)
          : (_currentMovie?.tmdbId == id);
      if (!ok) return;

      final String? bgSrc =
          _coerceHttpUrl(meta?.posterBg) ??
          _coerceHttpUrl(meta?.poster) ??
          _coerceHttpUrl(m.poster.toString()) ??
          _coerceHttpUrl(meta?.backdrop) ??
          _coerceHttpUrl(m.backdrop?.toString());

      if (bgSrc == null) return;

      try {
        await precacheImage(NetworkImage(bgSrc), context);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('HomeHeroCarousel: precache failed for $id: $e\n$st');
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Utils
  // ---------------------------------------------------------------------------

  String? _coerceHttpUrl(String? value) {
    if (value == null || value.isEmpty || value == 'null') return null;
    return (value.startsWith('http://') || value.startsWith('https://'))
        ? value
        : null;
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }
}

// -----------------------------------------------------------------------------
// Sélecteur d’images centralisé (poster et logo).
// Poster : priorité **no-lang** → **en** → meilleur score.
// Logo   : priorité **en** → **no-lang** → meilleur score.
// -----------------------------------------------------------------------------
class _ImageSelector {
  const _ImageSelector._();

  static String? selectPoster(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final List<Map<String, dynamic>> list = posters
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

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

  static String? selectLogo(List<dynamic> logos) {
    if (logos.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;
    double ratioOf(Map<String, dynamic> m) {
      final w = m['width'];
      final h = m['height'];
      final dw = (w is num)
          ? w.toDouble()
          : double.tryParse(w?.toString() ?? '') ?? 0;
      final dh = (h is num)
          ? h.toDouble()
          : double.tryParse(h?.toString() ?? '') ?? 0;
      if (dw <= 0 || dh <= 0) return 0;
      return dw / dh;
    }

    final List<Map<String, dynamic>> list = logos
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

    List<Map<String, dynamic>> sortByScore(List<Map<String, dynamic>> l) =>
        (l..sort((a, b) => scoreOf(b).compareTo(scoreOf(a))));
    List<Map<String, dynamic>> preferWide(List<Map<String, dynamic>> l) {
      final wide = l.where((m) => ratioOf(m) >= 2.0).toList();
      if (wide.isNotEmpty) return sortByScore(wide);
      return sortByScore(l);
    }

    final List<Map<String, dynamic>> en = list
        .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
        .toList();
    final enPref = preferWide(en);
    if (enPref.isNotEmpty) return pathOf(enPref.first);

    final List<Map<String, dynamic>> noLang = list
        .where((m) => m['iso_639_1'] == null)
        .toList();
    final noLangPref = preferWide(noLang);
    if (noLangPref.isNotEmpty) return pathOf(noLangPref.first);

    return pathOf(sortByScore(list).first);
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFF141414), Color(0x00141414)],
        ),
      ),
    );
  }
}

class _GlobalOverlay extends StatelessWidget {
  const _GlobalOverlay({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(color: Color.fromARGB(52, 20, 20, 20)),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141414), Color(0x00141414)],
        ),
      ),
    );
  }
}

class _HeroMeta {
  const _HeroMeta({
    required this.isTv,
    this.posterBg,
    this.poster,
    this.backdrop,
    this.logo,
    this.title,
    this.overview,
    this.year,
    this.rating,
    this.runtime,
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
  final int? runtime;
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({required this.overlayHeight});
  final double overlayHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF222222)),
              _BottomOverlay(height: overlayHeight),
              Positioned(
                left: 0,
                right: 0,
                bottom: overlayHeight - 100,
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 40,
                    height: 120,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Image.asset(AppAssets.iconAppLogo),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(children: [Expanded(child: SizedBox(height: 48))]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _HeroEmpty extends StatelessWidget {
  const _HeroEmpty({required this.overlayHeight});
  final double overlayHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF222222)),
              _BottomOverlay(height: overlayHeight),
              Positioned(
                left: 0,
                right: 0,
                bottom: overlayHeight - 100,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: const Text(
                      'Aucune tendance disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(children: [Expanded(child: SizedBox(height: 48))]),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

String? _formatDuration(int? minutes) {
  if (minutes == null || minutes <= 0) return null;
  if (minutes < 60) return '$minutes min';
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? '$h h' : '${h}h ${m}m';
}
