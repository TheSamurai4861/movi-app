// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/app_assets.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_favorite_button.dart';
import '../../../../core/widgets/movi_pill.dart';
import '../../../../core/widgets/movi_primary_button.dart';
import '../../../../shared/data/services/tmdb_cache_data_source.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../movie/data/datasources/tmdb_movie_remote_data_source.dart';
import '../../../tv/data/datasources/tmdb_tv_remote_data_source.dart';
import '../../../movie/domain/entities/movie_summary.dart';

/// Carrousel Hero: affiche jusqu'à 10 films tendances et fait tourner
/// automatiquement toutes les 7 secondes, avec un fondu limité au logo et
/// au backdrop. Les composants textuels restent en place (mise en page stable)
/// tandis que leur contenu change.
class HomeHeroCarousel extends StatefulWidget {
  const HomeHeroCarousel({super.key, required this.movies});

  final List<MovieSummary> movies;

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const double _totalHeight = 690;
  static const double _overlayHeight = 125;
  static const int _maxHeroCachePx = 1440;
  static const Duration _rotation = Duration(seconds: 9);
  static const Duration _fade = Duration(milliseconds: 800);

  final ValueNotifier<bool> _favorite = ValueNotifier<bool>(false);

  late final TmdbCacheDataSource _cache = sl<TmdbCacheDataSource>();
  late final TmdbImageResolver _images = sl<TmdbImageResolver>();
  late final TmdbMovieRemoteDataSource _moviesRemote =
      sl<TmdbMovieRemoteDataSource>();
  late final TmdbTvRemoteDataSource _tvRemote = sl<TmdbTvRemoteDataSource>();

  final Set<int> _hydratedIds = <int>{};
  final Map<int, Future<_HeroMeta?>> _metaFutures = {};

  int _index = 0;
  Timer? _timer;
  bool _backdropNotified = false;
  bool _isTransitioning = false;
  int? _pendingIndex;

  late final AnimationController _transitionCtrl =
      AnimationController(vsync: this, duration: _fade);
  late final Animation<double> _darkness =
      CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareCurrentMeta();
    _startTimer();
    _transitionCtrl.addStatusListener((status) {
      if (!_isTransitioning) return;
      if (status == AnimationStatus.completed) {
        // Phase 1 terminée (fond foncé). On bascule l’index puis on revient.
        if (_pendingIndex != null) {
          setState(() {
            _index = _pendingIndex!;
            _backdropNotified = false;
          });
          _prepareCurrentMeta();
        }
        _transitionCtrl.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Phase 2 terminée (retour à 0). Transition complète.
        _isTransitioning = false;
        _pendingIndex = null;
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.movies, widget.movies)) {
      _index = 0;
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
    _transitionCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

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

  void _prepareCurrentMeta() {
    final m = _currentMovie;
    if (m == null) return;
    final id = m.tmdbId;
    if (id == null) return;
    _metaFutures[id] ??= _loadMeta(m);
    _hydrateMetaIfNeeded(m);
    // Précache visuel du média courant
    _precacheBgFor(m, isNext: false);
    // Précache image suivante pour lisser la rotation
    final next = _nextMovie;
    if (next?.tmdbId != null) {
      _metaFutures[next!.tmdbId!] ??= _loadMeta(next);
      _hydrateMetaIfNeeded(next);
      _precacheBgFor(next, isNext: true);
    }
  }

  void _triggerNext() {
    if (_isTransitioning) return;
    final len = widget.movies.length;
    if (len <= 1) return;
    _pendingIndex = (_index + 1) % len;
    _isTransitioning = true;
    // Phase 1: aller vers fond foncé
    _transitionCtrl.forward(from: 0);
  }

  void _precacheBgFor(MovieSummary m, {required bool isNext}) {
    final id = m.tmdbId;
    if (id == null) return;
    final future = _metaFutures[id];
    if (future == null) return;
    future.then((meta) async {
      if (!mounted) return;
      final ok = isNext
          ? (_nextMovie?.tmdbId == id)
          : (_currentMovie?.tmdbId == id);
      if (!ok) return;

      final String? bgSrc =
          _coerceUrl(meta?.backdrop) ??
          _coerceUrl(meta?.poster) ??
          _coerceUrl(m.backdrop) ??
          _coerceUrl(m.poster);
      if (bgSrc == null) return;
      try {
        await precacheImage(NetworkImage(bgSrc), context);
      } catch (_) {}
    });
  }

  MovieSummary? get _currentMovie =>
      (widget.movies.isNotEmpty ? widget.movies[_index] : null);
  MovieSummary? get _nextMovie => widget.movies.isNotEmpty
      ? widget.movies[(_index + 1) % widget.movies.length]
      : null;

  // --- Helpers ---
  String? _coerceUrl(dynamic v) {
    if (v == null) return null;
    final s = v is Uri ? v.toString() : v.toString();
    if (s.isEmpty || s == 'null') return null;
    return (s.startsWith('http://') || s.startsWith('https://')) ? s : null;
  }

  Future<_HeroMeta?> _loadMeta(MovieSummary m) async {
    final id = m.tmdbId;
    if (id == null) return null;

    Map<String, dynamic>? data = await _safeGetMovieDetail(id);
    bool isTvData = false;
    if (data == null) {
      data = await _safeGetTvDetail(id);
      isTvData = data != null;
    }
    if (data == null) return null;

    final imagesMap =
        (data['images'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final posters =
        (imagesMap['posters'] as List<dynamic>?) ?? const <dynamic>[];
    final logos = (imagesMap['logos'] as List<dynamic>?) ?? const <dynamic>[];

    final posterNoLangPath =
        _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
    final logoPath = _selectLogoFrEnNoLang(logos);

    final posterUri = _images.poster(
      posterNoLangPath,
      size: 'w342',
    );
    final backdropUri = _images.backdrop(
      data['backdrop_path']?.toString(),
      size: 'w780',
    );
    final logoUri = _images.logo(logoPath);

    final overview = (data['overview']?.toString() ?? '').trim();
    final vote = (data['vote_average'] is num)
        ? (data['vote_average'] as num).toDouble()
        : null;

    int? runtimeMinutes;
    final rawRuntime = data['runtime'];
    if (rawRuntime is int) {
      runtimeMinutes = rawRuntime;
    } else {
      final ert = data['episode_run_time'];
      if (ert is List && ert.isNotEmpty) {
        final first = ert.first;
        if (first is int) runtimeMinutes = first;
      }
    }

    final String? releaseOrFirstAir =
        (data['release_date']?.toString().trim().isNotEmpty ?? false)
            ? data['release_date']?.toString()
            : data['first_air_date']?.toString();
    final year = _parseYear(releaseOrFirstAir) ?? m.releaseYear;

    return _HeroMeta(
      isTv: isTvData,
      poster: posterUri?.toString(),
      backdrop: backdropUri?.toString(),
      logo: logoUri?.toString(),
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
      runtime: runtimeMinutes,
    );
  }

  Future<void> _hydrateMetaIfNeeded(MovieSummary m) async {
    final id = m.tmdbId;
    if (id == null) return;
    if (_hydratedIds.contains(id)) return;

    Map<String, dynamic>? data = await _safeGetMovieDetail(id);
    bool isTvData = false;
    if (data == null) {
      data = await _safeGetTvDetail(id);
      isTvData = data != null;
    }

    if (data == null) {
      try {
        _hydratedIds.add(id);
        try {
          final dto = await _moviesRemote.fetchMovieFull(id);
          await _cache.putMovieDetail(id, dto.toCache());
        } catch (_) {
          final dto = await _tvRemote.fetchShowFull(id);
          await _cache.putTvDetail(id, dto.toCache());
        }
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {});
        });
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('HomeHeroCarousel: hydration (no cache) failed for $id: $e\n$st');
        }
      }
      return;
    }

    final imagesMap =
        (data['images'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final logos = (imagesMap['logos'] as List<dynamic>?) ?? const <dynamic>[];
    final overview = (data['overview']?.toString() ?? '').trim();
    final vote = (data['vote_average'] is num)
        ? (data['vote_average'] as num).toDouble()
        : null;
    final hasRuntime =
        data['runtime'] is int ||
        (data['episode_run_time'] is List &&
            (data['episode_run_time'] as List).isNotEmpty);

    final needsHydration =
        logos.isEmpty || overview.isEmpty || vote == null || !hasRuntime;
    if (!needsHydration) return;

    try {
      _hydratedIds.add(id);
      if (!isTvData) {
        final dto = await _moviesRemote.fetchMovieFull(id);
        await _cache.putMovieDetail(id, dto.toCache());
      } else {
        final dto = await _tvRemote.fetchShowFull(id);
        await _cache.putTvDetail(id, dto.toCache());
      }
      if (!mounted) return;
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

  Future<Map<String, dynamic>?> _safeGetMovieDetail(int id) async {
    try {
      return await _cache.getMovieDetail(id);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: getMovieDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetTvDetail(int id) async {
    try {
      return await _cache.getTvDetail(id);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: getTvDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  String? _selectPosterNoLang(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = posters.cast<Map<String, dynamic>>();

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  String? _selectLogoFrEnNoLang(List<dynamic> logos) {
    if (logos.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = logos.cast<Map<String, dynamic>>();

    final fr =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'fr'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (fr.isNotEmpty) return pathOf(fr.first);

    final en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;

    return SizedBox(
      height: _totalHeight,
      width: double.infinity,
      child: movie == null
          ? const _HeroSkeleton(overlayHeight: _overlayHeight)
          : FutureBuilder<_HeroMeta?>(
              future: _metaFutures[movie.tmdbId!],
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _HeroSkeleton(overlayHeight: _overlayHeight);
                }

                final meta = snap.data;

                final String? bgSrc =
                    _coerceUrl(meta?.backdrop) ??
                    _coerceUrl(meta?.poster) ??
                    _coerceUrl(movie.backdrop) ??
                    _coerceUrl(movie.poster);

                final hasLogo = (meta?.logo?.isNotEmpty ?? false);
                final year = meta?.year ?? movie.releaseYear;
                final yearText = (year ?? '—').toString();

                final rating = meta?.rating;
                final String? ratingText = (rating == null)
                    ? null
                    : (rating >= 10
                          ? rating.toStringAsFixed(0)
                          : rating.toStringAsFixed(1));

                final String? durationText = _formatDuration(meta?.runtime);
                final hasSynopsis = (meta?.overview?.isNotEmpty ?? false);

                Widget buildBackground() {
                  if (bgSrc != null) {
                    final mq = MediaQuery.of(context);
                    final rawPx = (mq.size.width * mq.devicePixelRatio).round();
                    final cacheWidth = rawPx.clamp(480, _maxHeroCachePx);
                    return Image.network(
                      bgSrc,
                      key: ValueKey(bgSrc),
                      fit: BoxFit.cover,
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
                  }
                  return const ColoredBox(color: Color(0xFF222222));
                }

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Backdrop fixe + overlay fondu vers fond foncé puis retour
                          buildBackground(),
                          AnimatedBuilder(
                            animation: _darkness,
                            builder: (context, _) {
                              return Opacity(
                                opacity: _darkness.value,
                                child: const ColoredBox(
                                  color: Color(0xFF141414),
                                ),
                              );
                            },
                          ),
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: _BottomOverlay(height: _overlayHeight),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: _overlayHeight - 100,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 100,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: hasLogo
                                        ? AnimatedBuilder(
                                            animation: _darkness,
                                            builder: (context, _) {
                                              return Opacity(
                                                opacity: 1.0 - _darkness.value,
                                                child: Image.network(
                                                  meta!.logo!,
                                                  key: ValueKey(meta.logo!),
                                                  height: 100,
                                                  gaplessPlayback: true,
                                                  cacheWidth: (300 * MediaQuery.of(context).devicePixelRatio).round(),
                                                  filterQuality: FilterQuality.low,
                                                  errorBuilder: (_, __, ___) =>
                                                      _TitleFallback(
                                                        movie.title.value,
                                                      ),
                                                ),
                                              );
                                            },
                                          )
                                        : _TitleFallback(
                                            movie.title.value,
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
                    Row(
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
                    const SizedBox(height: 16),
                    if (hasSynopsis)
                      Padding(
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
                      ),
                    if (hasSynopsis) const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MoviPrimaryButton(
                              label: 'Regarder maintenant',
                              assetIcon: AppAssets.iconPlay,
                              onPressed: () => context.push(AppRouteNames.movie),
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

class _TitleFallback extends StatelessWidget {
  const _TitleFallback(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _HeroMeta {
  const _HeroMeta({
    required this.isTv,
    this.poster,
    this.backdrop,
    this.logo,
    this.overview,
    this.year,
    this.rating,
    this.runtime,
  });

  final bool isTv;
  final String? poster;
  final String? backdrop;
  final String? logo;
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

String? _formatDuration(int? minutes) {
  if (minutes == null || minutes <= 0) return null;
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}