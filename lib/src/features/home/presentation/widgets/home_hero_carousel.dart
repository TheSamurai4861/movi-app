// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/performance/providers/performance_providers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/services/tmdb_image_selector_service.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';
import 'package:movi/src/core/preferences/preferences.dart';

import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_filter_bar.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Carrousel du Hero d'accueil.
/// - Affiche une liste de films/séries en rotation automatique.
/// - Lit d'abord le cache, puis hydrate si nécessaire (cache → prefetch lite).
/// - Hydratation complète déclenchée uniquement sur interaction.
/// - Sélection d'images centralisée pour éliminer les posters avec texte.
class HomeHeroCarousel extends ConsumerStatefulWidget {
  const HomeHeroCarousel({
    super.key,
    required this.items,
    this.onLoadingChanged,
  });

  final List<ContentReference> items;
  final ValueChanged<bool>? onLoadingChanged;

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
  static const double _totalHeight = HomeLayoutConstants.heroTotalHeight;
  static const double _overlayHeight = HomeLayoutConstants.heroOverlayHeight;

  // Timings
  static const Duration _rotation = HomeLayoutConstants.heroRotationDuration;
  static const Duration _fade = HomeLayoutConstants.heroFadeDuration;
  static const double _synopsisHeight = HomeLayoutConstants.heroSynopsisHeight;
  static const Duration _prefetchThrottle = Duration(milliseconds: 350);

  // DI
  late final TmdbCacheDataSource _cache;
  late final TmdbImageResolver _images;
  late final TmdbMovieRemoteDataSource _moviesRemote;
  late final TmdbTvRemoteDataSource _tvRemote;
  late final TmdbIdResolverService _tmdbIdResolver;
  late final LocalePreferences _localePreferences;

  // États
  final Set<int> _hydratedIds = <int>{};
  final Set<int> _hydratingIds = <int>{};
  final Set<int> _fullyHydratedIds = <int>{};
  final Set<int> _fullHydratingIds = <int>{};
  final Map<int, Future<_HeroMeta?>> _metaFutures = <int, Future<_HeroMeta?>>{};
  final Map<int, bool> _synopsisExpanded = <int, bool>{};
  final Set<int> _retriedIds = <int>{}; // Pour éviter les retries multiples

  int _index = 0;
  Timer? _timer;
  Timer? _prefetchTimer;
  DateTime? _lastPrefetchAt;
  bool _backdropNotified = false;
  
  // Flags pour éviter l'accumulation de callbacks
  bool _pendingStateUpdate = false;
  bool _lastNotifiedLoadingState = false;

  @override
  void initState() {
    super.initState();
    _cache = ref.read(_tmdbCacheProvider);
    _images = ref.read(_tmdbImagesProvider);
    _moviesRemote = ref.read(_tmdbMovieRemoteProvider);
    _tvRemote = ref.read(_tmdbTvRemoteProvider);
    _tmdbIdResolver = ref.read(slProvider)<TmdbIdResolverService>();
    _localePreferences = ref.read(slProvider)<LocalePreferences>();
    WidgetsBinding.instance.addObserver(this);
    final persistedIndex = ref.read(hp.homeHeroIndexProvider);
    if (persistedIndex > 0 && persistedIndex < widget.items.length) {
      _index = persistedIndex;
    }
    _prepareCurrentMeta();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items)) {
      final persistedIndex = ref.read(hp.homeHeroIndexProvider);
      final int maxIndex = (widget.items.length - 1);
      _index = (persistedIndex < 0)
          ? 0
          : (persistedIndex > maxIndex ? maxIndex : persistedIndex);
      _metaFutures.clear();
      _retriedIds.clear();
      _backdropNotified = false;
      _lastNotifiedLoadingState = false;
      _pendingStateUpdate = false;
      _prefetchTimer?.cancel();
      _prefetchTimer = null;
      _lastPrefetchAt = null;
      _prepareCurrentMeta();
      _restartTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    _prefetchTimer?.cancel();
    _prefetchTimer = null;
    _metaFutures.clear();
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

  /// Notifie le changement de loading state de manière débounced
  void _notifyLoadingStateIfChanged(bool isLoading) {
    if (_lastNotifiedLoadingState != isLoading) {
      _lastNotifiedLoadingState = isLoading;
      // Utiliser addPostFrameCallback pour éviter setState() pendant build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLoadingChanged?.call(isLoading);
        }
      });
    }
  }

  /// Planifie un setState si aucun n'est déjà en attente
  void _scheduleStateUpdate() {
    if (_pendingStateUpdate || !mounted) return;
    _pendingStateUpdate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingStateUpdate = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Rotation / préparation
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _timer?.cancel();
    if (widget.items.length <= 1) return;
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
    final int len = widget.items.length;
    if (len <= 1) return;
    final oldIndex = _index;
    debugPrint('[DEBUG][HomeHeroCarousel] _triggerNext: index $oldIndex -> ${(_index + 1) % len}');
    
    // Mise à jour de l'état
    _index = (_index + 1) % len;
    _backdropNotified = false;
    _retriedIds.clear();
    _lastNotifiedLoadingState = false; // Reset pour le nouvel item
    
    // Persister et préparer
    ref.read(hp.homeHeroIndexProvider.notifier).set(_index);
    _prepareCurrentMeta();
    
    // Planifier le rebuild
    _scheduleStateUpdate();
  }

  void _prepareCurrentMeta() {
    final now = DateTime.now();
    final last = _lastPrefetchAt;
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _prefetchThrottle) {
        _prefetchTimer?.cancel();
        _prefetchTimer = Timer(_prefetchThrottle - elapsed, () {
          if (!mounted) return;
          _prepareCurrentMetaNow();
        });
        return;
      }
    }
    _prepareCurrentMetaNow();
  }

  void _prepareCurrentMetaNow() {
    _lastPrefetchAt = DateTime.now();
    final ContentReference? current = _currentItem;
    final int? id = _tmdbIdOf(current);
    if (current == null || id == null) return;
    final tuning = ref.read(performanceTuningProvider);

    // Préparer meta courante (cache→affichage)
    _metaFutures[id] ??= _loadMetaWithRetry(current);
    // Hydrater l'item courant si nécessaire (prefetch "lite")
    _hydrateMetaIfNeeded(current);

    // Précharger image courante
    _precacheBgFor(current, isNext: false);

    final bool allowNextPrefetch = _isHeroVisible();
    if (!allowNextPrefetch) return;

    // Préparer meta suivante pour une transition fluide
    final ContentReference? next = _nextItem;
    final int? nextId = _tmdbIdOf(next);
    if (next != null && nextId != null) {
      _metaFutures[nextId] ??= _loadMetaWithRetry(next);
      // Hydrater aussi l'item suivant si nécessaire (prefetch "lite")
      _hydrateMetaIfNeeded(next);
      if (tuning.homeHeroPrecacheNextImage) {
        _precacheBgFor(next, isNext: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de données / cache
  // ---------------------------------------------------------------------------

  ContentReference? get _currentItem =>
      (widget.items.isNotEmpty ? widget.items[_index] : null);

  ContentReference? get _nextItem => widget.items.isNotEmpty
      ? widget.items[(_index + 1) % widget.items.length]
      : null;

  int? _tmdbIdOf(ContentReference? item) {
    if (item == null) return null;
    return int.tryParse(item.id.trim());
  }

  Future<_HeroMeta?> _loadMeta(ContentReference item) async {
    int? id = _tmdbIdOf(item);
    
    // Si pas de tmdbId et que c'est un ID Xtream, essayer de le trouver via recherche
    if (id == null && item.id.startsWith('xtream:')) {
      id = await _searchTmdbIdForContentReference(item);
      // Si on a trouvé un tmdbId, on continue avec ce nouvel ID
      if (id == null) return null;
    } else if (id == null) {
      return null;
    }

    final preferTvFirst = item.type == ContentType.series;

    // 1) Cache préféré (movie/tv selon type), sinon fallback
    Map<String, dynamic>? data = preferTvFirst
        ? await _safeGetTvDetail(id)
        : await _safeGetMovieDetail(id);
    bool isTvData = preferTvFirst;
    if (data == null) {
      data = preferTvFirst ? await _safeGetMovieDetail(id) : await _safeGetTvDetail(id);
      isTvData = data != null ? !preferTvFirst : preferTvFirst;
    }
    // Si le cache est vide, on retourne null (l'hydratation sera gérée par _loadMetaWithRetry)
    if (data == null) return null;

    final Map<String, dynamic> images =
        (data['images'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final List<dynamic> posters =
        (images['posters'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> logos =
        (images['logos'] as List<dynamic>?) ?? const <dynamic>[];

    // Hero: privilégier les posters "no-lang" (iso_639_1 == null), comme pour les films,
    // puis "en". On évite les posters localisés (souvent avec texte).
    final String? posterPath =
        _selectHeroPosterPath(posters) ?? data['poster_path']?.toString();
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
    final String? title = isTvData
        ? _nonEmptyOrNull(
            data['name']?.toString() ?? data['original_name']?.toString(),
          )
        : _nonEmptyOrNull(
            data['title']?.toString() ?? data['original_title']?.toString(),
          );

    final double? vote = (data['vote_average'] is num)
        ? (data['vote_average'] as num).toDouble()
        : null;

    // Durée (film) / durée épisode (série)
    int? runtimeMinutes;
    int? seasonsCount;
    if (!isTvData) {
      final dynamic rawRuntime = data['runtime'];
      if (rawRuntime is int) {
        runtimeMinutes = rawRuntime;
      }
    } else {
      final dynamic seasons = data['number_of_seasons'];
      if (seasons is int) {
        seasonsCount = seasons;
      }
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
    final int? year = _parseYear(date) ?? item.year;

    return _HeroMeta(
      isTv: isTvData,
      posterBg: posterBgUri?.toString(),
      poster: posterUri?.toString(),
      backdrop: backdropUri?.toString(),
      logo: logoUri?.toString(),
      title: title ?? item.title.value,
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
      runtime: runtimeMinutes,
      seasons: seasonsCount,
    );
  }

  /// Charge les métadonnées avec retry automatique si le cache est vide.
  /// 
  /// Stratégie :
  /// 1. Tente de charger depuis le cache via `_loadMeta`
  /// 2. Si null (cache vide), déclenche l'hydratation
  /// 3. Attend que l'hydratation soit terminée (avec timeout)
  /// 4. Réessaye de charger depuis le cache
  /// 5. Si toujours null après timeout, retourne null
  Future<_HeroMeta?> _loadMetaWithRetry(ContentReference item) async {
    int? id = _tmdbIdOf(item);
    
    // Si pas de tmdbId et que c'est un ID Xtream, essayer de le trouver via recherche
    if (id == null && item.id.startsWith('xtream:')) {
      id = await _searchTmdbIdForContentReference(item);
      // Si on a trouvé un tmdbId, on continue avec ce nouvel ID
      if (id == null) return null;
    } else if (id == null) {
      return null;
    }

    // Premier essai : charger depuis le cache
    final meta = await _loadMeta(item);
    if (meta != null) return meta;

    // Cache vide : déclencher l'hydratation si pas déjà en cours
    if (!_hydratedIds.contains(id) &&
        !_fullyHydratedIds.contains(id) &&
        !_hydratingIds.contains(id)) {
      // Déclencher l'hydratation de manière asynchrone (ne pas bloquer)
      unawaited(_hydrateMetaIfNeeded(item));
    }

    // Attendre que l'hydratation soit terminée (avec timeout)
    const timeout = Duration(seconds: 5);
    const checkInterval = Duration(milliseconds: 100);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      // Vérifier si l'hydratation est terminée
      if (_hydratedIds.contains(id) || _fullyHydratedIds.contains(id)) {
        // Réessayer de charger depuis le cache
        final retryMeta = await _loadMeta(item);
        if (retryMeta != null) return retryMeta;
        // Si toujours null après hydratation, abandonner
        break;
      }

      // Attendre un peu avant de réessayer
      await Future.delayed(checkInterval);
    }

    // Dernier essai après timeout ou si l'hydratation est terminée
    return await _loadMeta(item);
  }

  Future<void> _hydrateMetaIfNeeded(ContentReference item) async {
    final int? id = _tmdbIdOf(item);
    if (id == null ||
        _hydratedIds.contains(id) ||
        _fullyHydratedIds.contains(id) ||
        _hydratingIds.contains(id)) {
      return;
    }

    // Sauvegarder la langue au début pour éviter d'utiliser ref après await
    if (!mounted) return;
    final language = ref.read(asp.currentLanguageCodeProvider);

    final preferTvFirst = item.type == ContentType.series;
    Map<String, dynamic>? data = preferTvFirst
        ? await _safeGetTvDetail(id)
        : await _safeGetMovieDetail(id);
    bool isTvData = preferTvFirst;
    if (data == null) {
      data = preferTvFirst ? await _safeGetMovieDetail(id) : await _safeGetTvDetail(id);
      isTvData = data != null ? !preferTvFirst : preferTvFirst;
    }

    // Aucune donnée en cache → prefetch "lite" immédiat
    if (data == null) {
      _hydratingIds.add(id);
      _logHeroPrefetch(action: 'prefetch_lite', id: id);
      try {
        if (!preferTvFirst) {
          try {
            final dto = await _moviesRemote.fetchMovieWithImages(
              id,
              language: language,
            );
            await _cache.putMovieDetail(id, dto.toCache(), language: language);
          } catch (_) {
            final dto = await _tvRemote.fetchShowWithImages(
              id,
              language: language,
            );
            await _cache.putTvDetail(id, dto.toCache(), language: language);
          }
        } else {
          try {
            final dto = await _tvRemote.fetchShowWithImages(
              id,
              language: language,
            );
            await _cache.putTvDetail(id, dto.toCache(), language: language);
          } catch (_) {
            final dto = await _moviesRemote.fetchMovieWithImages(
              id,
              language: language,
            );
            await _cache.putMovieDetail(id, dto.toCache(), language: language);
          }
        }
        _hydratedIds.add(id);
        if (!mounted) return;
        _metaFutures[id] = _loadMeta(item);
        _scheduleStateUpdate();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint(
            'HomeHeroCarousel: hydration (no cache) failed for $id: $e\n$st',
          );
        }
      } finally {
        _hydratingIds.remove(id);
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

    if (_hydratingIds.contains(id)) return;
    _hydratingIds.add(id);
    _logHeroPrefetch(action: 'prefetch_lite', id: id);
    try {
      if (!isTvData) {
        final dto = await _moviesRemote.fetchMovieWithImages(
          id,
          language: language,
        );
        await _cache.putMovieDetail(id, dto.toCache(), language: language);
      } else {
        final dto = await _tvRemote.fetchShowWithImages(
          id,
          language: language,
        );
        await _cache.putTvDetail(id, dto.toCache(), language: language);
      }
      _hydratedIds.add(id);
      if (!mounted) return;
      _metaFutures[id] = _loadMeta(item);
      _scheduleStateUpdate();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: hydration failed for $id: $e\n$st');
      }
    } finally {
      _hydratingIds.remove(id);
    }
  }

  Future<void> _hydrateMetaFull(ContentReference item) async {
    final int? id = _tmdbIdOf(item);
    if (id == null ||
        _fullHydratingIds.contains(id) ||
        _fullyHydratedIds.contains(id)) {
      return;
    }
    // Sauvegarder la langue au début pour éviter d'utiliser ref après await
    if (!mounted) return;
    final language = ref.read(asp.currentLanguageCodeProvider);
    
    // Marquer comme en cours d'hydratation
    _fullHydratingIds.add(id);
    _logHeroPrefetch(action: 'prefetch_full', id: id);
    
    // Retry automatique pour les timeouts (2 tentatives avec backoff)
    int attempt = 0;
    const maxRetries = 2;
    bool success = false;
    
    try {
      while (attempt <= maxRetries && !success) {
        try {
          final preferTvFirst = item.type == ContentType.series;
          if (!preferTvFirst) {
            try {
              final dto =
                  await _moviesRemote.fetchMovieFull(id, language: language);
              await _cache.putMovieDetail(id, dto.toCache(), language: language);
            } catch (_) {
              final dto = await _tvRemote.fetchShowFull(id, language: language);
              await _cache.putTvDetail(id, dto.toCache(), language: language);
            }
          } else {
            try {
              final dto = await _tvRemote.fetchShowFull(id, language: language);
              await _cache.putTvDetail(id, dto.toCache(), language: language);
            } catch (_) {
              final dto =
                  await _moviesRemote.fetchMovieFull(id, language: language);
              await _cache.putMovieDetail(id, dto.toCache(), language: language);
            }
          }

          // Succès
          success = true;
          _fullyHydratedIds.add(id);
          if (!mounted) return;
          _metaFutures[id] = _loadMeta(item);
          _scheduleStateUpdate();
        } catch (e, st) {
          final isTimeout = e is TimeoutException ||
              (e.toString().toLowerCase().contains('timeout')) ||
              (e.toString().contains('Limiter acquire timeout'));

          if (!isTimeout || attempt >= maxRetries) {
            // Erreur non-retryable ou max retries atteint
            if (kDebugMode) {
              final errorType = isTimeout ? 'timeout' : 'permanent';
              debugPrint(
                'HomeHeroCarousel: hydration full failed ($errorType) for $id after ${attempt + 1} attempt(s): $e\n$st',
              );
            }
            break;
          }

          // Backoff exponentiel : 500ms, 1000ms
          final backoffDelay = Duration(milliseconds: 500 * (1 << attempt));
          if (kDebugMode) {
            debugPrint(
              'HomeHeroCarousel: hydration timeout for $id, retrying after ${backoffDelay.inMilliseconds}ms (attempt ${attempt + 1}/${maxRetries + 1})',
            );
          }
          await Future.delayed(backoffDelay);
          attempt++;
        }
      }
    } finally {
      _fullHydratingIds.remove(id);
    }
  }

  /// Recherche un tmdbId pour un ContentReference Xtream.
  ///
  /// Utilise TmdbIdResolverService pour rechercher le tmdbId par titre.
  Future<int?> _searchTmdbIdForContentReference(ContentReference item) async {
    try {
      final language = _localePreferences.languageCode;
      if (item.type == ContentType.movie) {
        return await _tmdbIdResolver.searchTmdbIdByTitleForMovie(
          title: item.title.value,
          releaseYear: item.year,
          language: language,
        );
      } else if (item.type == ContentType.series) {
        return await _tmdbIdResolver.searchTmdbIdByTitleForTv(
          title: item.title.value,
          releaseYear: item.year,
          language: language,
        );
      }
      return null;
    } catch (_) {
      // En cas d'erreur, retourner null pour utiliser le fallback
      return null;
    }
  }

  String? _nonEmptyOrNull(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String? _selectHeroPosterPath(List<dynamic> posters) {
    if (posters.isEmpty) return null;

    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();

    final List<Map<String, dynamic>> list = posters
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList(growable: false);
    if (list.isEmpty) return null;

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en = list
        .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
        .toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    return null;
  }

  Future<Map<String, dynamic>?> _safeGetMovieDetail(int id) async {
    if (!mounted) return null;
    final language = ref.read(asp.currentLanguageCodeProvider);
    try {
      return await _cache.getMovieDetail(id, language: language);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: getMovieDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> _safeGetTvDetail(int id) async {
    if (!mounted) return null;
    final language = ref.read(asp.currentLanguageCodeProvider);
    try {
      return await _cache.getTvDetail(id, language: language);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: getTvDetail($id) failed: $e\n$st');
      }
      return null;
    }
  }

  bool _isHeroVisible() {
    try {
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return true;
      }
      final offset = renderObject.localToGlobal(Offset.zero);
      final rect = offset & renderObject.size;
      final screen = Offset.zero & MediaQuery.of(context).size;
      return rect.overlaps(screen);
    } catch (_) {
      return true;
    }
  }

  void _logHeroPrefetch({
    required String action,
    required int id,
  }) {
    final ts = DateTime.now().toIso8601String();
    unawaited(
      LoggingService.log('[HeroPrefetch] ts=$ts id=$id action=$action'),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ContentReference? item = _currentItem;
    final int? tmdbId = _tmdbIdOf(item);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _totalHeight,
          width: double.infinity,
          child: (widget.items.isEmpty)
              ? const _HeroEmpty(overlayHeight: _overlayHeight)
              : item == null || tmdbId == null
              ? const _HeroSkeleton(overlayHeight: _overlayHeight)
              : FutureBuilder<_HeroMeta?>(
                  future: _metaFutures[tmdbId],
                  builder: (context, snap) {
                    final bool isLoadingMeta =
                        snap.connectionState == ConnectionState.waiting &&
                        snap.data == null;
                    
                    // Notifier le changement de loading state (débounced)
                    _notifyLoadingStateIfChanged(isLoadingMeta);
                    
                    final _HeroMeta? meta = snap.data;

                    // Si meta est null après completion, afficher un skeleton
                    // Le retry est déjà géré dans _hydrateMetaFull et _loadMetaWithRetry
                    // Ne PAS ajouter de retry ici car cela crée une boucle infinie de rebuilds

                    // Ordre de préférence du fond :
                    // 1) Poster TMDB (no-lang → en → best)
                    // 2) Poster playlist
                    // 3) Backdrop TMDB
                    // 4) Backdrop playlist
                    final String? bgSrc =
                        _coerceHttpUrl(meta?.posterBg) ??
                        _coerceHttpUrl(meta?.poster) ??
                        _coerceHttpUrl(item.poster?.toString()) ??
                        _coerceHttpUrl(meta?.backdrop);

                    Widget buildBackground() {
                      Widget image;
                      if (bgSrc != null) {
                        image = Image.network(
                          bgSrc,
                          key: ValueKey(bgSrc),
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.0, -0.5),
                          width: double.infinity,
                          height: double.infinity,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) {
                            if (!_backdropNotified) {
                              _backdropNotified = true;
                            }
                            return MoviPlaceholderCard(
                              type: item.type == ContentType.series
                                  ? PlaceholderType.series
                                  : PlaceholderType.movie,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.zero,
                            );
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
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
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

                    return Stack(
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
                        Positioned(
                          left: 0,
                          right: 0,
                          top: MediaQuery.of(context).padding.top + 12,
                          child: const HomeHeroFilterBar(),
                        ),
                        // Titre dans le Stack à 16px du bottomCenter
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: FutureBuilder<_HeroMeta?>(
                            future: _metaFutures[tmdbId],
                            builder: (context, snap) {
                              final _HeroMeta? meta = snap.data;
                              final bool hasTitle =
                                  meta?.title?.isNotEmpty ?? false;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: AnimatedSwitcher(
                                  duration: _fade,
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ...previous,
                                      if (current != null) current,
                                    ],
                                  ),
                                  child: Text(
                                    hasTitle ? meta!.title! : item.title.value,
                                    key: ValueKey(
                                      hasTitle
                                          ? '${tmdbId}_title'
                                          : '${tmdbId}_titleFallback',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        // Pills collées au Stack
        if (item != null && tmdbId != null)
          FutureBuilder<_HeroMeta?>(
            future: _metaFutures[tmdbId],
            builder: (context, snap) {
              final _HeroMeta? meta = snap.data;

              final int? year = meta?.year ?? item.year;
              final String yearText = (year ?? '—').toString();

              final double? rating = meta?.rating;
              final String? ratingText = (rating == null)
                  ? null
                  : (rating >= 10
                        ? rating.toStringAsFixed(0)
                        : rating.toStringAsFixed(1));

              final bool isTv =
                  meta?.isTv ?? (item.type == ContentType.series);
              final String? durationText =
                  isTv ? null : _formatDuration(meta?.runtime);

              final int? seasons = meta?.seasons;
              final String? seasonsText = (isTv && seasons != null && seasons > 0)
                  ? '$seasons ${seasons == 1 ? AppLocalizations.of(context)!.playlistSeasonSingular : AppLocalizations.of(context)!.playlistSeasonPlural}'
                  : null;

              return AnimatedSwitcher(
                duration: _fade,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [...previous, if (current != null) current],
                ),
                child: Row(
                  key: ValueKey('${tmdbId}_pills'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (durationText != null)
                      MoviPill(durationText, large: true),
                    if (durationText != null && year != null)
                      const SizedBox(width: 8),
                    if (seasonsText != null)
                      MoviPill(seasonsText, large: true),
                    if (seasonsText != null && year != null)
                      const SizedBox(width: 8),
                    if (year != null) MoviPill(yearText, large: true),
                    if (year != null && ratingText != null)
                      const SizedBox(width: 8),
                    if (ratingText != null)
                      MoviPill(
                        ratingText,
                        trailingIcon: Image.asset(
                          AppAssets.iconStarFilled,
                          width: 18,
                          height: 18,
                        ),
                        large: true,
                      ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        // Synopsis après les pills
        if (tmdbId != null)
          FutureBuilder<_HeroMeta?>(
            future: _metaFutures[tmdbId],
            builder: (context, snap) {
              final _HeroMeta? meta = snap.data;
              final bool hasSynopsis = (meta?.overview?.isNotEmpty ?? false);

              if (!hasSynopsis) {
                return SizedBox(
                  height: _synopsisHeight,
                  child: const SizedBox.shrink(),
                );
              }

              return AnimatedSwitcher(
                duration: _fade,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _buildSynopsis(
                  key: ValueKey('${tmdbId}_synopsis'),
                  overview: meta!.overview!,
                  tmdbId: tmdbId,
                ),
              );
            },
          )
        else
          SizedBox(height: _synopsisHeight, child: const SizedBox.shrink()),
        const SizedBox(height: 16),
        if (tmdbId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: MoviPrimaryButton(
                    label: AppLocalizations.of(context)!.homeWatchNow,
                    assetIcon: AppAssets.iconPlay,
                    onPressed: () => _openDetails(context),
                  ),
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final current = _currentItem;
                    if (current == null) {
                      return MoviFavoriteButton(
                        isFavorite: false,
                        onPressed: () {},
                      );
                    }
                    final id = current.id.trim();
                    if (id.isEmpty) {
                      return MoviFavoriteButton(isFavorite: false, onPressed: () {});
                    }

                    if (current.type == ContentType.series) {
                      final isFavoriteAsync = ref.watch(tvIsFavoriteProvider(id));
                      return isFavoriteAsync.when(
                        data: (isFavorite) => MoviFavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: () async {
                            await ref
                                .read(tvToggleFavoriteProvider.notifier)
                                .toggle(id);
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
                    }

                    final isFavoriteAsync = ref.watch(movieIsFavoriteProvider(id));
                    return isFavoriteAsync.when(
                      data: (isFavorite) => MoviFavoriteButton(
                        isFavorite: isFavorite,
                        onPressed: () async {
                          await ref
                              .read(movieToggleFavoriteProvider.notifier)
                              .toggle(id);
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
  }

  Future<void> _openDetails(BuildContext context) async {
    final current = _currentItem;
    if (current == null) return;

    final id = current.id.trim();
    if (id.isEmpty) return;

    if (!mounted || !context.mounted) return;

    unawaited(_hydrateMetaFull(current));

    if (current.type == ContentType.series) {
      await navigateToTvDetail(context, ref, ContentRouteArgs.series(id));
      return;
    }

    await navigateToMovieDetail(context, ref, ContentRouteArgs.movie(id));
  }

  // ---------------------------------------------------------------------------
  // Pré-chargement images
  // ---------------------------------------------------------------------------

  void _precacheBgFor(ContentReference item, {required bool isNext}) {
    final int? id = _tmdbIdOf(item);
    if (id == null) return;

    final Future<_HeroMeta?>? future = _metaFutures[id];
    if (future == null) return;

    future.then((meta) async {
      if (!mounted) return;

      final bool ok = isNext ? (_tmdbIdOf(_nextItem) == id) : (_tmdbIdOf(_currentItem) == id);
      if (!ok) return;

      final String? bgSrc =
          _coerceHttpUrl(meta?.posterBg) ??
          _coerceHttpUrl(meta?.poster) ??
          _coerceHttpUrl(item.poster?.toString()) ??
          _coerceHttpUrl(meta?.backdrop);

      if (bgSrc == null) return;

      try {
        if (!mounted || !context.mounted) return;
        await precacheImage(NetworkImage(bgSrc), context);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('HomeHeroCarousel: precache failed for $id: $e\n$st');
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------

  Widget _buildSynopsis({
    required Key key,
    required String overview,
    required int tmdbId,
  }) {
    final bool isExpanded = _synopsisExpanded[tmdbId] ?? false;

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth - (AppSpacing.lg * 2);
        final bool needsExpansion = _needsExpansion(overview, maxWidth);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  overview,
                  maxLines: isExpanded ? null : 3,
                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              if (needsExpansion)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _synopsisExpanded[tmdbId] = !isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpanded
                                ? AppLocalizations.of(context)!.actionCollapse
                                : AppLocalizations.of(context)!.actionExpand,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _needsExpansion(String text, double maxWidth) {
    // Vérifier si le texte dépasse 3 lignes en utilisant un TextPainter
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
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
      decoration: const BoxDecoration(color: Color.fromARGB(26, 20, 20, 20)),
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
    this.seasons,
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
  final int? seasons;
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
                top: MediaQuery.of(context).padding.top + 12,
                child: const HomeHeroFilterBar(),
              ),
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
                      child: Consumer(
                        builder: (context, ref, _) {
                          final accentColor = ref.watch(
                            asp.currentAccentColorProvider,
                          );
                          return SvgPicture.asset(
                            AppAssets.iconAppLogoSvg,
                            colorFilter: ColorFilter.mode(
                              accentColor,
                              BlendMode.srcIn,
                            ),
                          );
                        },
                      ),
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
                top: MediaQuery.of(context).padding.top + 12,
                child: const HomeHeroFilterBar(),
              ),
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

String? _formatDuration(int? minutes) {
  if (minutes == null || minutes <= 0) return null;
  if (minutes < 60) return '$minutes min';
  final int h = minutes ~/ 60;
  final int m = minutes % 60;
  return m == 0 ? '$h h' : '${h}h ${m}m';
}
