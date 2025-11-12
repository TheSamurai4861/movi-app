// ignore_for_file: public_member_api_docs

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

/// Hero principal de la page d’accueil.
/// - Lecture via cache pour l’affichage initial.
/// - Hydratation asynchrone (cache→réseau) si des métadonnées essentielles manquent.
/// - Résout les images via [TmdbImageResolver] avec des tailles adaptées (w780/w500).
class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key, required this.movie, this.onBackgroundReady});

  /// Résumé du contenu sélectionné pour le hero (MovieSummary minimal).
  final MovieSummary? movie;
  /// Callback déclenché dès que le backdrop rend sa première frame.
  final VoidCallback? onBackgroundReady;

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  static const double _totalHeight = 690;
  static const double _overlayHeight = 125;
  // Plafond sécurité pour la taille décodée du backdrop (en pixels @device)
  static const int _maxHeroCachePx = 1440;

  final ValueNotifier<bool> _favorite = ValueNotifier<bool>(false);

  late final TmdbCacheDataSource _cache = sl<TmdbCacheDataSource>();
  late final TmdbImageResolver _images = sl<TmdbImageResolver>();
  late final TmdbMovieRemoteDataSource _moviesRemote =
      sl<TmdbMovieRemoteDataSource>();
  late final TmdbTvRemoteDataSource _tvRemote = sl<TmdbTvRemoteDataSource>();

  /// Évite les hydrations multiples pour un même identifiant durant le cycle de vie.
  final Set<int> _hydratedIds = <int>{};

  Future<_HeroMeta?>? _metaFuture;
  bool _backdropNotified = false; // évite les notifications multiples

  @override
  void initState() {
    super.initState();
    _primeMeta();
  }

  @override
  void didUpdateWidget(covariant HomeHeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.movie?.tmdbId;
    final newId = widget.movie?.tmdbId;
    if (oldId != newId) _primeMeta();
  }

  @override
  void dispose() {
    _favorite.dispose();
    super.dispose();
  }

  void _primeMeta() {
    final m = widget.movie;
    if (m == null) {
      _metaFuture = null;
      return;
    }
    _metaFuture = _loadMeta(m);
    // Hydrater en arrière-plan si nécessaire (ne bloque pas l'affichage initial).
    _hydrateMetaIfNeeded(m);
  }

  /// Tente d’extraire une URL http(s) depuis diverses représentations (String / Uri / null).
  String? _coerceUrl(dynamic v) {
    if (v == null) return null;
    final s = v is Uri ? v.toString() : v.toString();
    if (s.isEmpty || s == 'null') return null;
    return (s.startsWith('http://') || s.startsWith('https://')) ? s : null;
  }

  Future<_HeroMeta?> _loadMeta(MovieSummary m) async {
    final id = m.tmdbId;
    if (id == null) return null;

    // 1) Essai cache Movie
    Map<String, dynamic>? data = await _safeGetMovieDetail(id);

    // 2) Fallback cache TV si le hero pointe en réalité vers une série (ou cache movie non hydraté)
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

    // ✅ Utiliser des tailles adaptées pour réduire la pression mémoire/CPU
    // Spécification: réduire la taille de l'image du hero et optimiser le poids.
    // - Poster: passer de w500 à w342 (moins lourd, suffisant pour ce contexte)
    // - Backdrop: conserver w780 (compromis qualité/poids pour fond plein écran)
    final posterUri = _images.poster(
      posterNoLangPath,
      size: 'original',
    );
    final backdropUri = _images.backdrop(
      data['backdrop_path']?.toString(),
      size: 'original',
    );
    final logoUri = _images.logo(logoPath);

    final overview = (data['overview']?.toString() ?? '').trim();
    final vote = (data['vote_average'] is num)
        ? (data['vote_average'] as num).toDouble()
        : null;

    // Durée (Movie: runtime en minutes, TV: premier élément de episode_run_time si présent).
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

    // Year depuis release_date (Movie) **ou** first_air_date (TV).
    final String? releaseOrFirstAir =
        (data['release_date']?.toString().trim().isNotEmpty ?? false)
        ? data['release_date']?.toString()
        : data['first_air_date']?.toString();
    final year = _parseYear(releaseOrFirstAir) ?? widget.movie?.releaseYear;

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

    // Lire le cache pour décider si une hydratation est nécessaire.
    Map<String, dynamic>? data = await _safeGetMovieDetail(id);
    bool isTvData = false;
    if (data == null) {
      data = await _safeGetTvDetail(id);
      isTvData = data != null;
    }

    // Si aucune entrée de cache, hydrater directement en FULL (film puis fallback série).
    if (data == null) {
      try {
        _hydratedIds.add(id);
        try {
          final dto = await _moviesRemote.fetchMovieFull(id);
          await _cache.putMovieDetail(id, dto.toCache());
          isTvData = false;
        } catch (_) {
          // Fallback série si l’ID correspond à un show.
          final dto = await _tvRemote.fetchShowFull(id);
          await _cache.putTvDetail(id, dto.toCache());
          isTvData = true;
        }
        if (!mounted) return;
        // Décaler la mise à jour en post-frame pour ne pas perturber la première peinture
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _metaFuture = _loadMeta(m);
          });
        });
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            'HomeHeroSection: hydration (no cache) failed for $id: $e\n$st',
          );
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
        // Film: récupérer le détail complet (inclut images/logos, crédits, recommandations).
        final dto = await _moviesRemote.fetchMovieFull(id);
        await _cache.putMovieDetail(id, dto.toCache());
      } else {
        // Série: détail complet.
        final dto = await _tvRemote.fetchShowFull(id);
        await _cache.putTvDetail(id, dto.toCache());
      }
      if (!mounted) return;
      // Recalculer les métadonnées à partir du cache hydraté en post-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _metaFuture = _loadMeta(m);
        });
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroSection: hydration failed for $id: $e\n$st');
      }
    }
  }

  Future<Map<String, dynamic>?> _safeGetMovieDetail(int id) async {
    try {
      return await _cache.getMovieDetail(id);
    } catch (e, st) {
      if (kDebugMode) {
        // En debug uniquement : signaler une incohérence de cache.
        debugPrint('HomeHeroSection: getMovieDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetTvDetail(int id) async {
    try {
      return await _cache.getTvDetail(id);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroSection: getTvDetail($id) failed: $e\n$st');
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
    final movie = widget.movie;

    return SizedBox(
      height: _totalHeight,
      width: double.infinity,
      child: movie == null
          ? const _HeroSkeleton(overlayHeight: _overlayHeight)
          : FutureBuilder<_HeroMeta?>(
              future: _metaFuture,
              builder: (context, snap) {
                // État de chargement initial ou rafraîchissement cible.
                if (snap.connectionState == ConnectionState.waiting) {
                  return const _HeroSkeleton(overlayHeight: _overlayHeight);
                }

                final meta = snap.data;

                // Priorité: backdrop > poster > fallback summary (backdrop/poster).
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

                // Construit le fond du hero en limitant la résolution décodée côté client (cacheWidth)
                // afin de réduire la consommation mémoire/CPU et accélérer le premier rendu.
                Widget buildBackground() {
                  if (bgSrc != null) {
                    final mq = MediaQuery.of(context);
                    final rawPx = (mq.size.width * mq.devicePixelRatio).round();
                    // Évite les décodages géants sur desktop lors des resizes
                    final cacheWidth = rawPx.clamp(480, _maxHeroCachePx);
                    return Image.network(
                      bgSrc,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      // ✅ réduit le churn d’images et la charge sur le main thread (Windows)
                      gaplessPlayback: true,
                      // Réduit le poids décodé en adaptant à la largeur réelle de l’écran
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) {
                        // Si l’image échoue, on ne bloque pas l’UI :
                        // on signale le “ready” pour que l’overlay se ferme.
                        if (!_backdropNotified) {
                          _backdropNotified = true;
                          widget.onBackgroundReady?.call();
                        }
                        return const ColoredBox(color: Color(0xFF222222));
                      },
                      // Fermer l’overlay dès la première frame du backdrop
                      frameBuilder: (context, child, frame, wasSync) {
                        if (frame != null && !_backdropNotified) {
                          _backdropNotified = true;
                          widget.onBackgroundReady?.call();
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
                          buildBackground(),
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
                                        ? Image.network(
                                            meta!.logo!,
                                            height: 100,
                                            gaplessPlayback: true,
                                            // Limite la résolution décodée du logo (~300px @1x)
                                            cacheWidth: (300 * MediaQuery.of(context).devicePixelRatio).round(),
                                            filterQuality: FilterQuality.low,
                                            errorBuilder: (_, __, ___) =>
                                                _TitleFallback(
                                                  movie.title.value,
                                                ),
                                          )
                                        : _TitleFallback(movie.title.value),
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
                              onPressed: () =>
                                  context.push(AppRouteNames.movie),
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
                    // Bloc: largeur = largeur écran - 40px, hauteur = 120px
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
