// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/widgets/widgets.dart';

import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';

import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart' as hp;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';

/// Hero principal de la page d'accueil.
/// - Affiche d'abord les données disponibles (cache / résumé).
/// - Hydrate asynchronement le cache si des métadonnées clés manquent.
/// - Sélection d'image centralisée : poster TMDB **sans langue** en priorité,
///   sinon EN, sinon meilleur score ; fallback sur poster de la playlist.
class HomeHeroSection extends ConsumerStatefulWidget {
  const HomeHeroSection({
    super.key,
    required this.movie,
    this.onBackgroundReady,
    this.onLoadingChanged,
  });

  /// Résumé minimal pour initialiser le hero.
  final MovieSummary? movie;

  /// Notifié quand l'image de fond rend sa première frame.
  final VoidCallback? onBackgroundReady;

  /// Notifié quand l'état de chargement des métadonnées change.
  final ValueChanged<bool>? onLoadingChanged;

  @override
  ConsumerState<HomeHeroSection> createState() => _HomeHeroSectionState();
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

class _HomeHeroSectionState extends ConsumerState<HomeHeroSection> {
  // Mise en page
  static const double _totalHeight = 500;
  static const double _overlayHeight = 125;

  // Sécurité décodage image (px @device)
  static const int _maxHeroCachePx = 1440;


  late final TmdbCacheDataSource _cache;
  late final TmdbImageResolver _images;
  late final TmdbMovieRemoteDataSource _moviesRemote;
  late final TmdbTvRemoteDataSource _tvRemote;

  final Set<String> _hydratedKeys = <String>{};

  String? _lastLanguageCode;
  _HeroMeta? _lastMeta;
  Timer? _langDebounce;

  Future<_HeroMeta?>? _metaFuture;
  bool _backdropNotified = false;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _cache = ref.read(_tmdbCacheProvider);
    _images = ref.read(_tmdbImagesProvider);
    _moviesRemote = ref.read(_tmdbMovieRemoteProvider);
    _tvRemote = ref.read(_tmdbTvRemoteProvider);
    _lastLanguageCode = ref.read(currentLanguageCodeProvider);
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
    _langDebounce?.cancel();
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  void _primeMeta() {
    final movie = widget.movie;
    if (movie == null) {
      _metaFuture = null;
      return;
    }
    _metaFuture = _loadMeta(movie);
    _hydrateMetaIfNeeded(movie); // non bloquant
  }

  // ---------------------------------------------------------------------------
  // CHARGEMENT / HYDRATATION
  // ---------------------------------------------------------------------------

  Future<_HeroMeta?> _loadMeta(MovieSummary m) async {
    final int? id = m.tmdbId;
    if (id == null) return null;

    // 1) Cache film puis fallback cache série (au cas où l’ID pointe vers une série)
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

    // Sélection centralisée : poster no-lang → en → best ; pour le logo : en → no-lang → best
    final String? posterPath =
        _ImageSelector.selectPoster(posters) ?? data['poster_path']?.toString();
    final String? posterBgPath = data['poster_background']?.toString();
    final String? logoPath = _ImageSelector.selectLogo(logos);

    // Tailles raisonnables pour limiter la pression mémoire CPU/GPU.
    // - poster : w500 (qualité suffisante pour le hero)
    // - backdrop : w780 (compromis qualité/poids pour le plein écran)
    final Uri? posterUri = _images.poster(posterPath, size: 'w500');
    final Uri? posterBgUri = _images.poster(posterBgPath, size: 'w780');
    final Uri? backdropUri = _images.backdrop(
      data['backdrop_path']?.toString(),
      size: 'w780',
    );
    final Uri? logoUri = _images.logo(logoPath); // taille par défaut adaptée

    final String overview = (data['overview']?.toString() ?? '').trim();
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

    // Année (release_date pour film, first_air_date pour série)
    final String? date =
        (data['release_date']?.toString().trim().isNotEmpty ?? false)
        ? data['release_date']?.toString()
        : data['first_air_date']?.toString();
    final int? year = _parseYear(date) ?? widget.movie?.releaseYear;

    return _HeroMeta(
      isTv: isTvData,
      posterBg: posterBgUri?.toString(),
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
    final int? id = m.tmdbId;
    if (id == null) return;
    final String key = '$id|${ref.read(currentLanguageCodeProvider)}';
    if (_hydratedKeys.contains(key)) return;

    Map<String, dynamic>? data = await _safeGetMovieDetail(id);
    bool isTvData = false;
    if (data == null) {
      data = await _safeGetTvDetail(id);
      isTvData = data != null;
    }

    // Si pas de cache du tout : fetch FULL immédiatement (film puis fallback série)
    if (data == null) {
      try {
        _hydratedKeys.add(key);
        try {
          final dto = await _moviesRemote.fetchMovieFull(
            id,
            language: ref.read(currentLanguageCodeProvider),
            cancelToken: _cancelToken,
          );
          await _cache.putMovieDetail(
            id,
            dto.toCache(),
            language: ref.read(currentLanguageCodeProvider),
          );
          isTvData = false;
        } catch (_) {
          final dto = await _tvRemote.fetchShowFull(
            id,
            language: ref.read(currentLanguageCodeProvider),
            cancelToken: _cancelToken,
          );
          await _cache.putTvDetail(
            id,
            dto.toCache(),
            language: ref.read(currentLanguageCodeProvider),
          );
          isTvData = true;
        }
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _metaFuture = _loadMeta(m));
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

    // Cache présent : vérifier si des champs essentiels manquent
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
      _hydratedKeys.add(key);
      if (!isTvData) {
        final dto = await _moviesRemote.fetchMovieFull(
          id,
          language: ref.read(currentLanguageCodeProvider),
          cancelToken: _cancelToken,
        );
        await _cache.putMovieDetail(
          id,
          dto.toCache(),
          language: ref.read(currentLanguageCodeProvider),
        );
      } else {
        final dto = await _tvRemote.fetchShowFull(
          id,
          language: ref.read(currentLanguageCodeProvider),
          cancelToken: _cancelToken,
        );
        await _cache.putTvDetail(
          id,
          dto.toCache(),
          language: ref.read(currentLanguageCodeProvider),
        );
      }
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _metaFuture = _loadMeta(m));
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroSection: hydration failed for $id: $e\n$st');
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
        debugPrint('HomeHeroSection: getMovieDetail($id) failed: $e\n$st');
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
        debugPrint('HomeHeroSection: getTvDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final MovieSummary? movie = widget.movie;

    final String lang = ref.watch(currentLanguageCodeProvider);
    if (lang != _lastLanguageCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _onLanguageChanged(lang);
      });
    }

    return SizedBox(
      height: _totalHeight,
      width: double.infinity,
      child: movie == null
          ? const _HeroSkeleton(overlayHeight: _overlayHeight)
          : FutureBuilder<_HeroMeta?>(
              future: _metaFuture,
              builder: (context, snap) {
                final bool isLoadingMeta = snap.connectionState == ConnectionState.waiting && snap.data == null && _lastMeta == null;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onLoadingChanged?.call(isLoadingMeta);
                });
                final _HeroMeta? meta = snap.data ?? _lastMeta;
                if (snap.connectionState == ConnectionState.done &&
                    snap.data != null) {
                  _lastMeta = snap.data;
                }
                if (snap.connectionState == ConnectionState.waiting &&
                    meta == null) {
                  return const _HeroSkeleton(overlayHeight: _overlayHeight);
                }

                // Ordre de préférence du fond :
                // 1) Poster TMDB sélectionné (no-lang → en → best)
                // 2) Poster playlist (MovieSummary)
                // 3) Backdrop TMDB
                // 4) Backdrop playlist
                final String? bgSrc =
                    _coerceHttpUrl(meta?.posterBg) ??
                    _coerceHttpUrl(meta?.poster) ??
                    _coerceHttpUrl(movie.poster.toString()) ??
                    _coerceHttpUrl(meta?.backdrop) ??
                    _coerceHttpUrl(movie.backdrop?.toString());

                if (bgSrc == null) {
                  return const _HeroEmpty(overlayHeight: _overlayHeight);
                }

                final bool hasLogo = (meta?.logo?.isNotEmpty ?? false);
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
                  // Limiter le décodage pour réduire la pression mémoire/CPU (Windows/Desktop).
                  final mq = MediaQuery.of(context);
                  final int rawPx = (mq.size.width * mq.devicePixelRatio)
                      .round();
                  final int cacheWidth = rawPx.clamp(480, _maxHeroCachePx);
                  return Image.network(
                    bgSrc,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    cacheWidth: cacheWidth,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) {
                      if (!_backdropNotified) {
                        _backdropNotified = true;
                        widget.onBackgroundReady?.call();
                      }
                      return Image.asset(
                        AppAssets.placeholderPosterMovie,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    },
                    frameBuilder: (context, child, frame, wasSync) {
                      if (frame != null && !_backdropNotified) {
                        _backdropNotified = true;
                        widget.onBackgroundReady?.call();
                      }
                      return child;
                    },
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
                                            // ~300px @1x pour limiter le poids décodé
                                            cacheWidth:
                                                (300 *
                                                        MediaQuery.of(
                                                          context,
                                                        ).devicePixelRatio)
                                                    .round(),
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
                          MoviPill(
                            ratingText,
                            large: true,
                            trailingIcon: Image.asset(
                              AppAssets.iconStarFilled,
                              width: 18,
                              height: 18,
                            ),
                          ),
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
                          Consumer(
                            builder: (context, ref, _) {
                              final m = widget.movie;
                              if (m == null) {
                                return Expanded(
                                  child: MoviPrimaryButton(
                                    label: AppLocalizations.of(context)!.homeWatchNow,
                                    assetIcon: AppAssets.iconPlay,
                                    onPressed: () => _playMovie(context),
                                  ),
                                );
                              }
                              final historyAsync = ref.watch(
                                hp.mediaHistoryProvider((contentId: m.id.value, type: ContentType.movie)),
                              );
                              return Expanded(
                                child: MoviPrimaryButton(
                                  label: historyAsync.when(
                                    data: (entry) => entry != null ? 'Reprendre la lecture' : AppLocalizations.of(context)!.homeWatchNow,
                                    loading: () => AppLocalizations.of(context)!.homeWatchNow,
                                    error: (_, __) => AppLocalizations.of(context)!.homeWatchNow,
                                  ),
                                  assetIcon: AppAssets.iconPlay,
                                  onPressed: () => _playMovie(context),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Consumer(
                            builder: (context, ref, _) {
                              final m = widget.movie;
                              if (m == null) {
                                return MoviFavoriteButton(
                                  isFavorite: false,
                                  onPressed: () {},
                                );
                              }
                              final movieId = m.id.value;
                              final isFavoriteAsync = ref.watch(
                                movieIsFavoriteProvider(movieId),
                              );
                              return isFavoriteAsync.when(
                                data: (isFavorite) => MoviFavoriteButton(
                                  isFavorite: isFavorite,
                                  onPressed: () async {
                                    await ref.read(
                                      movieToggleFavoriteProvider.notifier,
                                    ).toggle(movieId);
                                  },
                                ),
                                loading: () => MoviFavoriteButton(
                                  isFavorite: false,
                                  onPressed: () {},
                                ),
                                error: (_, __) => MoviFavoriteButton(
                                  isFavorite: false,
                                  onPressed: () {},
                                ),
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
  // Lecture du film
  // ---------------------------------------------------------------------------

  Future<void> _playMovie(BuildContext context) async {
    final m = widget.movie;
    if (m == null) return;

    try {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final vault = locator<CredentialsVault>();
      final logger = locator<AppLogger>();
      final urlBuilder = XtreamStreamUrlBuilder(
        iptvLocal: iptvLocal,
        vault: vault,
      );

      final movieId = m.id.value;
      final title = m.title.display;

      // Chercher l'item Xtream correspondant
      XtreamPlaylistItem? xtreamItem;
      final accounts = await iptvLocal.getAccounts();

      logger.debug(
        'Recherche du film movieId=$movieId dans ${accounts.length} comptes',
      );

      for (final account in accounts) {
        final playlists = await iptvLocal.getPlaylists(account.id);
        logger.debug('Compte ${account.id}: ${playlists.length} playlists');

        // Recherche globale dans toutes les playlists (movies et series)
        // car certains films peuvent être mal catégorisés
        for (final playlist in playlists) {
          logger.debug(
            'Playlist ${playlist.title} (${playlist.type.name}): ${playlist.items.length} items',
          );

          // Si l'ID commence par "xtream:", chercher par streamId
          if (movieId.startsWith('xtream:')) {
            final streamIdStr = movieId.substring(7);
            final streamId = int.tryParse(streamIdStr);
            logger.debug('Recherche par streamId=$streamId (xtream)');
            if (streamId != null) {
              try {
                // Chercher dans tous les items, peu importe le type
                xtreamItem = playlist.items.firstWhere(
                  (item) => item.streamId == streamId,
                );
                logger.debug(
                  'Film trouvé: ${xtreamItem.title} (streamId=${xtreamItem.streamId}, tmdbId=${xtreamItem.tmdbId}, type=${xtreamItem.type.name})',
                );
              } catch (_) {
                // Item non trouvé, continuer la recherche
                logger.debug(
                  'Film avec streamId=$streamId non trouvé dans ${playlist.title}',
                );
              }
            }
          } else {
            // Sinon, chercher par tmdbId
            final tmdbId = int.tryParse(movieId);
            logger.debug('Recherche par tmdbId=$tmdbId');
            if (tmdbId != null) {
              try {
                // Chercher dans tous les items, peu importe le type
                xtreamItem = playlist.items.firstWhere(
                  (item) => item.tmdbId == tmdbId,
                );
                logger.debug(
                  'Film trouvé: ${xtreamItem.title} (streamId=${xtreamItem.streamId}, tmdbId=${xtreamItem.tmdbId}, type=${xtreamItem.type.name})',
                );
              } catch (_) {
                // Item non trouvé, continuer la recherche
                logger.debug(
                  'Film avec tmdbId=$tmdbId non trouvé dans ${playlist.title}',
                );
              }
            }
          }

          if (xtreamItem != null) break;
        }
        if (xtreamItem != null) break;
      }

      if (xtreamItem == null) {
        logger.info('Film movieId=$movieId non trouvé dans les playlists');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Film non disponible dans la playlist')),
        );
        return;
      }

      // Construire l'URL de streaming
      // Vérifier que c'est bien un film, sinon adapter
      String? streamUrl;
      if (xtreamItem.type == XtreamPlaylistItemType.movie) {
        streamUrl = await urlBuilder.buildStreamUrlFromMovieItem(xtreamItem);
      } else {
        // Si c'est une série trouvée par erreur, on ne peut pas la lire comme un film
        logger.warn(
          'Item trouvé est de type ${xtreamItem.type.name}, pas un film',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le média trouvé n\'est pas un film')),
        );
        return;
      }

      if (streamUrl == null) {
        logger.error(
          'Impossible de construire l\'URL pour streamId=${xtreamItem.streamId}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de construire l\'URL de streaming'),
          ),
        );
        return;
      }

      logger.debug('URL de streaming construite: $streamUrl');

      // Ouvrir le player
      context.push(
        AppRouteNames.player,
        extra: VideoSource(
          url: streamUrl,
          title: title,
          contentId: movieId,
          contentType: ContentType.movie,
          poster: m.poster,
        ),
      );
    } catch (e, st) {
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error('Erreur lors de la lecture du film: $e', e, st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _onLanguageChanged(String newLang) {
    _cancelToken?.cancel('language_changed');
    _langDebounce?.cancel();
    _langDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _cancelToken = CancelToken();
      _lastLanguageCode = newLang;
      final MovieSummary? m = widget.movie;
      if (m == null) {
        setState(() => _metaFuture = null);
        return;
      }
      setState(() => _metaFuture = _loadMeta(m));
      _hydrateMetaIfNeeded(m);
    });
  }

  // ---------------------------------------------------------------------------
  // Utils
  // ---------------------------------------------------------------------------

  /// Retourne une URL http(s) uniquement, ou null.
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
// Sélecteur d’images (centralisé au niveau du widget pour éviter toute
// divergence interne). Pour une centralisation globale, déplacer ce bloc
// dans un util partagé et le réutiliser côté repository & widgets.
// -----------------------------------------------------------------------------
class _ImageSelector {
  const _ImageSelector._();

  /// Sélection du poster : priorité **no-lang** → **en** → meilleur score.
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

  /// Sélection du logo : priorité **en** → **no-lang** → meilleur score.
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
    this.posterBg,
    this.poster,
    this.backdrop,
    this.logo,
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
                    child: Text(
                      AppLocalizations.of(context)!.homeNoTrends,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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

// Formatage lisible : util libre, pas lié à l’état.
String? _formatDuration(int? minutes) {
  if (minutes == null || minutes <= 0) return null;
  if (minutes < 60) return '$minutes min';
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
