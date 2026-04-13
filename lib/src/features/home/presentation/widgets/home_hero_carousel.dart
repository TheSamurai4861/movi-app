// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/performance/providers/performance_providers.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/responsive/presentation/extensions/responsive_context.dart';

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
    this.primaryActionFocusNode,
    this.moviesFilterFocusNode,
    this.layoutHeight,
  });

  final List<ContentReference> items;
  final ValueChanged<bool>? onLoadingChanged;
  final FocusNode? primaryActionFocusNode;
  final FocusNode? moviesFilterFocusNode;
  final double? layoutHeight;

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
  static const double _desktopVisualBleed =
      HomeLayoutConstants.heroDesktopVisualBleed;
  // Timings
  static const Duration _rotation = HomeLayoutConstants.heroRotationDuration;
  static const Duration _fade = HomeLayoutConstants.heroFadeDuration;
  static const double _synopsisHeight = HomeLayoutConstants.heroSynopsisHeight;
  static const Duration _prefetchThrottle = Duration(milliseconds: 350);
  static const Duration _heroPrecacheTimeout = Duration(seconds: 4);

  // DI
  late final TmdbCacheDataSource _cache;
  late final TmdbImageResolver _images;
  late final TmdbMovieRemoteDataSource _moviesRemote;
  late final TmdbTvRemoteDataSource _tvRemote;
  late final TmdbIdResolverService _tmdbIdResolver;
  late final LocalePreferences _localePreferences;
  late final PerformanceDiagnosticLogger _diagnostics;

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

  // Flags pour éviter l'accumulation de callbacks
  bool _pendingStateUpdate = false;
  bool _lastNotifiedLoadingState = false;
  bool _isBackgroundWorkSuspended = false;
  bool _visibilitySyncScheduled = false;
  bool _hasInitializedDependencies = false;
  bool _initialHeroWarmupPending = true;
  int _heroWorkGeneration = 0;
  int? _activeLiteHydrationId;
  int? _activePrecacheId;
  final Set<int> _precachedBgIds = <int>{};
  String? _lastLoggedHeroBuildSignature;
  String? _lastLoggedResolvedMediaSignature;
  ScreenType _screenType = ScreenType.mobile;

  KeyEventResult _handlePrimaryActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final moviesNode = widget.moviesFilterFocusNode;
    if (moviesNode == null ||
        moviesNode.context == null ||
        !moviesNode.canRequestFocus) {
      return KeyEventResult.handled;
    }
    moviesNode.requestFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleFavoriteActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final moviesNode = widget.moviesFilterFocusNode;
    if (moviesNode == null ||
        moviesNode.context == null ||
        !moviesNode.canRequestFocus) {
      return KeyEventResult.handled;
    }
    moviesNode.requestFocus();
    return KeyEventResult.handled;
  }

  void _logHeroDebug(
    String event, {
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final message = <String>[
      '[HomeHeroDebug]',
      'surface=carousel',
      'event=$event',
      'platform=${defaultTargetPlatform.name}',
      for (final entry in context.entries)
        if (entry.value != null) '${entry.key}=${entry.value}',
    ].join(' ');
    unawaited(LoggingService.log(message, category: 'home_hero_debug'));
  }

  @override
  void initState() {
    super.initState();
    _cache = ref.read(_tmdbCacheProvider);
    _images = ref.read(_tmdbImagesProvider);
    _moviesRemote = ref.read(_tmdbMovieRemoteProvider);
    _tvRemote = ref.read(_tmdbTvRemoteProvider);
    _tmdbIdResolver = ref.read(slProvider)<TmdbIdResolverService>();
    _localePreferences = ref.read(slProvider)<LocalePreferences>();
    _diagnostics = ref.read(slProvider)<PerformanceDiagnosticLogger>();
    WidgetsBinding.instance.addObserver(this);
    final persistedIndex = ref.read(hp.homeHeroIndexProvider);
    if (persistedIndex > 0 && persistedIndex < widget.items.length) {
      _index = persistedIndex;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final previousScreenType = _screenType;
    _screenType = context.screenType;

    if (!_hasInitializedDependencies) {
      _hasInitializedDependencies = true;
      _logHeroDebug(
        'dependencies_ready',
        context: <String, Object?>{
          'items': widget.items.length,
          'screenType': _screenType.name,
          'useLargeHeroImages': _useLargeHeroImages,
        },
      );
      _prepareCurrentMeta();
      _startTimer();
      return;
    }

    if (previousScreenType != _screenType) {
      _handleScreenTypeChanged(previousScreenType);
    }
  }

  @override
  void didUpdateWidget(covariant HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items)) {
      _invalidateHeroWorkGeneration();
      final persistedIndex = ref.read(hp.homeHeroIndexProvider);
      final int maxIndex = (widget.items.length - 1);
      _index = (persistedIndex < 0)
          ? 0
          : (persistedIndex > maxIndex ? maxIndex : persistedIndex);
      _metaFutures.clear();
      _precachedBgIds.clear();
      _retriedIds.clear();
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
    _precachedBgIds.clear();
    super.dispose();
  }

  // Lifecycle : pause/reprise du timer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeBackgroundWork(reason: 'app_resumed');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _suspendBackgroundWork(reason: 'app_inactive');
    }
  }

  bool get _canRunBackgroundWork =>
      mounted && !_isBackgroundWorkSuspended && _isHeroVisible();

  int _invalidateHeroWorkGeneration() {
    _resetBackgroundWorkState();
    return ++_heroWorkGeneration;
  }

  bool _isCurrentHeroWorkToken(int workToken) =>
      mounted && workToken == _heroWorkGeneration;

  bool _isCurrentHeroItemToken(
    int workToken, {
    required int tmdbId,
    required bool isNext,
  }) {
    if (!_isCurrentHeroWorkToken(workToken)) {
      return false;
    }
    final expectedId = isNext ? _tmdbIdOf(_nextItem) : _tmdbIdOf(_currentItem);
    return expectedId == tmdbId;
  }

  void _retryCurrentHeroPreparationIfNeeded({required int completedTmdbId}) {
    final int? currentId = _tmdbIdOf(_currentItem);
    if (currentId == null || currentId == completedTmdbId) {
      return;
    }
    if (!_canRunBackgroundWork) {
      return;
    }
    _prepareCurrentMeta();
  }

  void _resetBackgroundWorkState() {
    _activeLiteHydrationId = null;
    _activePrecacheId = null;
    _prefetchTimer?.cancel();
    _prefetchTimer = null;
    _lastPrefetchAt = null;
  }

  void _releaseLiteHydrationLock(int tmdbId) {
    if (_activeLiteHydrationId == tmdbId) {
      _activeLiteHydrationId = null;
    }
    _hydratingIds.remove(tmdbId);
  }

  void _releasePrecacheLock(int tmdbId) {
    if (_activePrecacheId == tmdbId) {
      _activePrecacheId = null;
    }
  }

  void _logHeroAbandoned(
    String operation, {
    required Stopwatch stopwatch,
    required Map<String, Object?> context,
  }) {
    _diagnostics.mark(
      operation,
      event: 'abandoned',
      context: <String, Object?>{
        'durationMs': stopwatch.elapsed.inMilliseconds,
        ...context,
      },
    );
  }

  void _scheduleVisibilitySync() {
    if (_visibilitySyncScheduled || !mounted) {
      return;
    }
    _visibilitySyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilitySyncScheduled = false;
      if (!mounted) {
        return;
      }
      final isVisible = _isHeroVisible();
      if (isVisible) {
        if (_isBackgroundWorkSuspended) {
          _resumeBackgroundWork(reason: 'hero_visible');
        }
        return;
      }
      if (!_isBackgroundWorkSuspended) {
        _suspendBackgroundWork(reason: 'hero_not_visible');
      }
    });
  }

  void _suspendBackgroundWork({required String reason}) {
    _invalidateHeroWorkGeneration();
    if (_isBackgroundWorkSuspended) return;
    _isBackgroundWorkSuspended = true;
    _timer?.cancel();
    _timer = null;
    _diagnostics.mark(
      'home_hero_background_work',
      event: 'suspended',
      context: <String, Object?>{'reason': reason},
    );
  }

  void _resumeBackgroundWork({required String reason}) {
    if (!_isHeroVisible()) {
      _diagnostics.mark(
        'home_hero_background_work',
        event: 'resume_deferred',
        context: <String, Object?>{'reason': reason},
      );
      _isBackgroundWorkSuspended = true;
      _scheduleVisibilitySync();
      return;
    }
    if (!_isBackgroundWorkSuspended && _timer != null) return;
    _isBackgroundWorkSuspended = false;
    _diagnostics.mark(
      'home_hero_background_work',
      event: 'resumed',
      context: <String, Object?>{'reason': reason},
    );
    _prepareCurrentMeta();
    _restartTimer();
  }

  /// Notifie le changement de loading state de manière débounced
  void _notifyLoadingStateIfChanged(bool isLoading) {
    if (_lastNotifiedLoadingState != isLoading) {
      _lastNotifiedLoadingState = isLoading;
      _logHeroDebug(
        'loading_changed',
        context: <String, Object?>{'isLoading': isLoading},
      );
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
    if (widget.items.length <= 1 || !_canRunBackgroundWork) return;
    _timer = Timer.periodic(_rotation, (_) {
      if (!_canRunBackgroundWork) return;
      _triggerNext();
    });
  }

  void _restartTimer() {
    _timer?.cancel();
    _startTimer();
  }

  void _triggerNext() {
    if (!_canRunBackgroundWork) {
      _suspendBackgroundWork(reason: 'hero_not_visible');
      return;
    }
    final int len = widget.items.length;
    if (len <= 1) return;
    final oldIndex = _index;
    if (kDebugMode) {
      debugPrint(
        '[DEBUG][HomeHeroCarousel] _triggerNext: index $oldIndex -> ${(_index + 1) % len}',
      );
    }

    // Mise à jour de l'état
    _invalidateHeroWorkGeneration();
    _index = (_index + 1) % len;
    _retriedIds.clear();
    _lastNotifiedLoadingState = false; // Reset pour le nouvel item

    // Persister et préparer
    ref.read(hp.homeHeroIndexProvider.notifier).set(_index);
    _prepareCurrentMeta();

    // Planifier le rebuild
    _scheduleStateUpdate();
  }

  void _prepareCurrentMeta() {
    if (!_canRunBackgroundWork) {
      _diagnostics.mark(
        'home_hero_prepare',
        event: 'skipped',
        context: <String, Object?>{
          'reason': _isBackgroundWorkSuspended
              ? 'background_work_suspended'
              : 'hero_not_visible',
        },
      );
      return;
    }
    final now = DateTime.now();
    final workToken = _heroWorkGeneration;
    final last = _lastPrefetchAt;
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < _prefetchThrottle) {
        _prefetchTimer?.cancel();
        _prefetchTimer = Timer(_prefetchThrottle - elapsed, () {
          if (!_isCurrentHeroWorkToken(workToken)) return;
          _prepareCurrentMetaNow(workToken: workToken);
        });
        return;
      }
    }
    _prepareCurrentMetaNow(workToken: workToken);
  }

  void _prepareCurrentMetaNow({required int workToken}) {
    final ContentReference? current = _currentItem;
    final int? id = _tmdbIdOf(current);
    if (current == null || id == null) return;
    final bool isInitialHeroWarmup = _initialHeroWarmupPending;
    // Ne reporter que le précache image (léger) au 2e passage ; l'hydratation TMDB
    // du slide courant doit toujours pouvoir tourner au premier frame sinon le
    // premier hero reste souvent sans métadonnées (cache froid).
    _initialHeroWarmupPending = false;
    final bool heroVisible = _canRunBackgroundWork;
    _diagnostics.mark(
      'home_hero_prepare',
      context: <String, Object?>{
        'currentId': id,
        'currentType': current.type.name,
        'items': widget.items.length,
        'heroVisible': heroVisible,
        'initialWarmup': isInitialHeroWarmup,
      },
    );
    _logHeroDebug(
      'prepare_now',
      context: <String, Object?>{
        'currentId': id,
        'currentType': current.type.name,
        'heroVisible': heroVisible,
        'initialWarmup': isInitialHeroWarmup,
        'workToken': workToken,
        'nextId': _tmdbIdOf(_nextItem),
      },
    );
    if (!heroVisible) {
      _diagnostics.mark(
        'home_hero_prepare',
        event: 'skipped',
        context: <String, Object?>{
          'currentId': id,
          'reason': _isBackgroundWorkSuspended
              ? 'background_work_suspended'
              : 'hero_not_visible',
        },
      );
      return;
    }
    _lastPrefetchAt = DateTime.now();

    // Préparer meta courante (cache→affichage), puis hydratation réseau dédiée.
    _metaFutures[id] = _loadMetaWithRetry(current, workToken: workToken);
    _logHeroDebug(
      'meta_future_assigned',
      context: <String, Object?>{'currentId': id, 'workToken': workToken},
    );
    _hydrateMetaIfNeeded(current, workToken: workToken);
    if (!isInitialHeroWarmup) {
      _precacheBgFor(current, isNext: false, workToken: workToken);
    }
    // Préparer meta suivante pour une transition fluide
    final ContentReference? next = _nextItem;
    final int? nextId = _tmdbIdOf(next);
    if (next != null && nextId != null) {
      // Le slide suivant ne doit pas déclencher d'I/O réseau.
      // On ne prépare qu'une lecture cache pour garder une transition fluide
      // et laisser le réseau au slide courant.
      _metaFutures[nextId] ??= _loadMeta(next);
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

  bool get _useLargeHeroImages =>
      _screenType == ScreenType.desktop ||
      _screenType == ScreenType.tablet ||
      _screenType == ScreenType.tv;

  bool get _disableHeroPrecacheOnCurrentPlatform =>
      defaultTargetPlatform == TargetPlatform.windows;

  String get _heroPosterSize {
    if (!_useLargeHeroImages) return 'w500';
    return 'w780';
  }

  String get _heroPosterBackgroundSize {
    if (!_useLargeHeroImages) return 'w780';
    return 'w1280';
  }

  String get _heroBackdropSize {
    if (!_useLargeHeroImages) return 'w780';
    return 'w1280';
  }

  String get _heroPrecachePosterSize => _useLargeHeroImages ? 'w780' : 'w500';

  String get _heroPrecachePosterBackgroundSize =>
      _useLargeHeroImages ? 'w780' : 'w500';

  String get _heroPrecacheBackdropSize =>
      _useLargeHeroImages ? 'w1280' : 'w780';

  bool get _isWideHeroLayout =>
      _screenType == ScreenType.desktop ||
      _screenType == ScreenType.tablet ||
      _screenType == ScreenType.tv;

  bool get _shouldExtendDesktopHero =>
      _screenType == ScreenType.desktop || _screenType == ScreenType.tv;

  Alignment get _heroContentAlignment => _screenType == ScreenType.desktop
      ? const Alignment(-1, 0.24)
      : Alignment.centerLeft;

  void _handleScreenTypeChanged(ScreenType previousScreenType) {
    _logHeroDebug(
      'screen_type_changed',
      context: <String, Object?>{
        'previousScreenType': previousScreenType.name,
        'screenType': _screenType.name,
        'currentId': _tmdbIdOf(_currentItem),
      },
    );
    _invalidateHeroWorkGeneration();
    _metaFutures.clear();
    _precachedBgIds.clear();
    _retriedIds.clear();
    _lastNotifiedLoadingState = false;
    _prepareCurrentMeta();
    _restartTimer();
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
      data = preferTvFirst
          ? await _safeGetMovieDetail(id)
          : await _safeGetTvDetail(id);
      isTvData = data != null ? !preferTvFirst : preferTvFirst;
    }
    // Si le cache est vide, on retourne null (l'hydratation réseau : _hydrateMetaIfNeeded)
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
    final preferredLang = (ref.read(
      asp.currentLanguageCodeProvider,
    )).split('-').first;
    final String? logoPath = TmdbImageSelectorService.selectLogoPath(
      logos,
      preferredLang: preferredLang,
    );

    // Sur grands écrans, le hero doit consommer une source plus généreuse
    // pour éviter le flou sur desktop/tablette/TV.
    final Uri? posterUri = _images.poster(posterPath, size: _heroPosterSize);
    final Uri? posterBgUri = _images.poster(
      posterBgPath,
      size: _heroPosterBackgroundSize,
    );
    final Uri? backdropUri = _images.backdrop(
      data['backdrop_path']?.toString(),
      size: _heroBackdropSize,
    );
    final Uri? precachePosterUri = _images.poster(
      posterPath,
      size: _heroPrecachePosterSize,
    );
    final Uri? precachePosterBgUri = _images.poster(
      posterBgPath,
      size: _heroPrecachePosterBackgroundSize,
    );
    final Uri? precacheBackdropUri = _images.backdrop(
      data['backdrop_path']?.toString(),
      size: _heroPrecacheBackdropSize,
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
    _logHeroDebug(
      'load_meta_resolved',
      context: <String, Object?>{
        'tmdbId': id,
        'itemType': item.type.name,
        'isTvData': isTvData,
        'hasPosterBg': posterBgUri != null,
        'hasPoster': posterUri != null,
        'hasBackdrop': backdropUri != null,
        'posterSize': _heroPosterSize,
        'posterBgSize': _heroPosterBackgroundSize,
        'backdropSize': _heroBackdropSize,
        'precachePosterSize': _heroPrecachePosterSize,
        'precacheBackdropSize': _heroPrecacheBackdropSize,
      },
    );

    return _HeroMeta(
      isTv: isTvData,
      posterBg: posterBgUri?.toString(),
      poster: posterUri?.toString(),
      backdrop: backdropUri?.toString(),
      precachePosterBg: precachePosterBgUri?.toString(),
      precachePoster: precachePosterUri?.toString(),
      precacheBackdrop: precacheBackdropUri?.toString(),
      logo: logoUri?.toString(),
      title: title ?? item.title.value,
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
      runtime: runtimeMinutes,
      seasons: seasonsCount,
    );
  }

  /// Charge les métadonnées depuis le cache uniquement (pas d’I/O réseau).
  ///
  /// L’hydratation TMDB est déclenchée par [_hydrateMetaIfNeeded] depuis
  /// [_prepareCurrentMetaNow] pour tous les slides, y compris le premier.
  ///
  /// La future ne doit pas rester bloquée à attendre le réseau: le carousel
  /// affiche immédiatement son état minimal et se ré-enrichit quand l'I/O
  /// termine.
  Future<_HeroMeta?> _loadMetaWithRetry(
    ContentReference item, {
    required int workToken,
  }) async {
    if (!_canRunBackgroundWork) {
      return null;
    }
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
    if (!_isCurrentHeroWorkToken(workToken)) {
      return null;
    }
    if (meta != null) return meta;

    return null;
  }

  Future<void> _hydrateMetaIfNeeded(
    ContentReference item, {
    required int workToken,
  }) async {
    if (!_canRunBackgroundWork) {
      return;
    }
    final int? id = _tmdbIdOf(item);
    if (id == null ||
        _hydratedIds.contains(id) ||
        _fullyHydratedIds.contains(id) ||
        _hydratingIds.contains(id)) {
      return;
    }
    if (_activeLiteHydrationId != null && _activeLiteHydrationId != id) {
      _diagnostics.mark(
        'home_hero_hydrate',
        event: 'skipped',
        context: <String, Object?>{
          'tmdbId': id,
          'reason': 'another_hydration_active',
          'activeTmdbId': _activeLiteHydrationId,
        },
      );
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
      data = preferTvFirst
          ? await _safeGetMovieDetail(id)
          : await _safeGetTvDetail(id);
      isTvData = data != null ? !preferTvFirst : preferTvFirst;
    }

    // Aucune donnée en cache → prefetch "lite" immédiat
    if (data == null) {
      _hydratingIds.add(id);
      _activeLiteHydrationId = id;
      _logHeroPrefetch(action: 'prefetch_lite', id: id);
      final stopwatch = Stopwatch()..start();
      try {
        if (!preferTvFirst) {
          try {
            final dto = await _moviesRemote.fetchMovieWithImages(
              id,
              language: language,
            );
            if (!_isCurrentHeroWorkToken(workToken)) {
              _logHeroAbandoned(
                'home_hero_hydrate',
                stopwatch: stopwatch,
                context: <String, Object?>{
                  'tmdbId': id,
                  'contentType': item.type.name,
                  'reason': 'stale_work_token_after_fetch',
                },
              );
              return;
            }
            await _cache.putMovieDetail(id, dto.toCache(), language: language);
          } catch (_) {
            final dto = await _tvRemote.fetchShowWithImages(
              id,
              language: language,
            );
            if (!_isCurrentHeroWorkToken(workToken)) {
              _logHeroAbandoned(
                'home_hero_hydrate',
                stopwatch: stopwatch,
                context: <String, Object?>{
                  'tmdbId': id,
                  'contentType': item.type.name,
                  'reason': 'stale_work_token_after_fetch',
                },
              );
              return;
            }
            await _cache.putTvDetail(id, dto.toCache(), language: language);
          }
        } else {
          try {
            final dto = await _tvRemote.fetchShowWithImages(
              id,
              language: language,
            );
            if (!_isCurrentHeroWorkToken(workToken)) {
              _logHeroAbandoned(
                'home_hero_hydrate',
                stopwatch: stopwatch,
                context: <String, Object?>{
                  'tmdbId': id,
                  'contentType': item.type.name,
                  'reason': 'stale_work_token_after_fetch',
                },
              );
              return;
            }
            await _cache.putTvDetail(id, dto.toCache(), language: language);
          } catch (_) {
            final dto = await _moviesRemote.fetchMovieWithImages(
              id,
              language: language,
            );
            if (!_isCurrentHeroWorkToken(workToken)) {
              _logHeroAbandoned(
                'home_hero_hydrate',
                stopwatch: stopwatch,
                context: <String, Object?>{
                  'tmdbId': id,
                  'contentType': item.type.name,
                  'reason': 'stale_work_token_after_fetch',
                },
              );
              return;
            }
            await _cache.putMovieDetail(id, dto.toCache(), language: language);
          }
        }
        _hydratedIds.add(id);
        if (!_isCurrentHeroItemToken(workToken, tmdbId: id, isNext: false)) {
          _logHeroAbandoned(
            'home_hero_hydrate',
            stopwatch: stopwatch,
            context: <String, Object?>{
              'tmdbId': id,
              'contentType': item.type.name,
              'reason': 'current_item_changed_before_commit',
            },
          );
          return;
        }
        _metaFutures[id] = _loadMeta(item);
        _scheduleStateUpdate();
        _diagnostics.completed(
          'home_hero_hydrate',
          elapsed: stopwatch.elapsed,
          context: <String, Object?>{
            'tmdbId': id,
            'contentType': item.type.name,
            'reason': 'cache_miss',
          },
        );
      } catch (e, st) {
        _diagnostics.failed(
          'home_hero_hydrate',
          elapsed: stopwatch.elapsed,
          error: e,
          stackTrace: st,
          context: <String, Object?>{
            'tmdbId': id,
            'contentType': item.type.name,
            'reason': 'cache_miss',
          },
        );
        if (kDebugMode) {
          debugPrint(
            'HomeHeroCarousel: hydration (no cache) failed for $id: $e\n$st',
          );
        }
      } finally {
        _releaseLiteHydrationLock(id);
        _retryCurrentHeroPreparationIfNeeded(completedTmdbId: id);
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
    _activeLiteHydrationId = id;
    _logHeroPrefetch(action: 'prefetch_lite', id: id);
    final stopwatch = Stopwatch()..start();
    try {
      if (!isTvData) {
        final dto = await _moviesRemote.fetchMovieWithImages(
          id,
          language: language,
        );
        if (!_isCurrentHeroWorkToken(workToken)) {
          _logHeroAbandoned(
            'home_hero_hydrate',
            stopwatch: stopwatch,
            context: <String, Object?>{
              'tmdbId': id,
              'contentType': item.type.name,
              'reason': 'stale_work_token_after_fetch',
            },
          );
          return;
        }
        await _cache.putMovieDetail(id, dto.toCache(), language: language);
      } else {
        final dto = await _tvRemote.fetchShowWithImages(id, language: language);
        if (!_isCurrentHeroWorkToken(workToken)) {
          _logHeroAbandoned(
            'home_hero_hydrate',
            stopwatch: stopwatch,
            context: <String, Object?>{
              'tmdbId': id,
              'contentType': item.type.name,
              'reason': 'stale_work_token_after_fetch',
            },
          );
          return;
        }
        await _cache.putTvDetail(id, dto.toCache(), language: language);
      }
      _hydratedIds.add(id);
      if (!_isCurrentHeroItemToken(workToken, tmdbId: id, isNext: false)) {
        _logHeroAbandoned(
          'home_hero_hydrate',
          stopwatch: stopwatch,
          context: <String, Object?>{
            'tmdbId': id,
            'contentType': item.type.name,
            'reason': 'current_item_changed_before_commit',
          },
        );
        return;
      }
      _metaFutures[id] = _loadMeta(item);
      _scheduleStateUpdate();
      _diagnostics.completed(
        'home_hero_hydrate',
        elapsed: stopwatch.elapsed,
        context: <String, Object?>{
          'tmdbId': id,
          'contentType': item.type.name,
          'reason': 'cache_incomplete',
        },
      );
    } catch (e, st) {
      _diagnostics.failed(
        'home_hero_hydrate',
        elapsed: stopwatch.elapsed,
        error: e,
        stackTrace: st,
        context: <String, Object?>{
          'tmdbId': id,
          'contentType': item.type.name,
          'reason': 'cache_incomplete',
        },
      );
      if (kDebugMode) {
        debugPrint('HomeHeroCarousel: hydration failed for $id: $e\n$st');
      }
    } finally {
      _releaseLiteHydrationLock(id);
      _retryCurrentHeroPreparationIfNeeded(completedTmdbId: id);
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
              final dto = await _moviesRemote.fetchMovieFull(
                id,
                language: language,
              );
              await _cache.putMovieDetail(
                id,
                dto.toCache(),
                language: language,
              );
            } catch (_) {
              final dto = await _tvRemote.fetchShowFull(id, language: language);
              await _cache.putTvDetail(id, dto.toCache(), language: language);
            }
          } else {
            try {
              final dto = await _tvRemote.fetchShowFull(id, language: language);
              await _cache.putTvDetail(id, dto.toCache(), language: language);
            } catch (_) {
              final dto = await _moviesRemote.fetchMovieFull(
                id,
                language: language,
              );
              await _cache.putMovieDetail(
                id,
                dto.toCache(),
                language: language,
              );
            }
          }

          // Succès
          success = true;
          _fullyHydratedIds.add(id);
          if (!mounted) return;
          _metaFutures[id] = _loadMeta(item);
          _scheduleStateUpdate();
        } catch (e, st) {
          final isTimeout =
              e is TimeoutException ||
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

    final en =
        list
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

  void _logHeroPrefetch({required String action, required int id}) {
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
    const iconActionFocusedBackground = Color(0x807A7A7A);
    _scheduleVisibilitySync();
    final ContentReference? item = _currentItem;
    final int? tmdbId = _tmdbIdOf(item);
    final bool isWideHero = _isWideHeroLayout;
    final bool shouldExtendDesktopHero = _shouldExtendDesktopHero;
    final Alignment heroContentAlignment = _heroContentAlignment;
    final double layoutHeight = widget.layoutHeight ?? _totalHeight;
    final double visualBleed = shouldExtendDesktopHero
        ? _desktopVisualBleed
        : 0;
    final double heroHeight = isWideHero
        ? layoutHeight + visualBleed
        : MediaQuery.of(context).size.height *
              HomeLayoutConstants.heroMobileStackHeightFactor;
    final overlaySpec = MoviHeroOverlaySpec.home(isWideLayout: isWideHero);
    final buildSignature = [
      widget.items.length,
      _index,
      tmdbId,
      isWideHero,
      heroHeight.round(),
      _canRunBackgroundWork,
      _isBackgroundWorkSuspended,
    ].join('|');
    if (_lastLoggedHeroBuildSignature != buildSignature) {
      _lastLoggedHeroBuildSignature = buildSignature;
      _logHeroDebug(
        'build_state',
        context: <String, Object?>{
          'items': widget.items.length,
          'index': _index,
          'tmdbId': tmdbId,
          'isWideHero': isWideHero,
          'heroHeight': heroHeight.round(),
          'canRunBackgroundWork': _canRunBackgroundWork,
          'backgroundWorkSuspended': _isBackgroundWorkSuspended,
        },
      );
    }

    final Widget heroBody = SizedBox(
      width: double.infinity,
      child: (widget.items.isEmpty)
          ? _HeroEmpty(heroHeight: heroHeight, isWideHero: isWideHero)
          : item == null || tmdbId == null
          ? _HeroSkeleton(heroHeight: heroHeight, isWideHero: isWideHero)
          : FutureBuilder<_HeroMeta?>(
              future: _metaFutures[tmdbId],
              builder: (context, snap) {
                final bool isLoadingMeta =
                    snap.connectionState == ConnectionState.waiting &&
                    snap.data == null;

                _notifyLoadingStateIfChanged(isLoadingMeta);

                final _HeroMeta? meta = snap.data;
                final posterBackground = _coerceHttpUrl(meta?.posterBg);
                final poster =
                    _coerceHttpUrl(meta?.poster) ??
                    _coerceHttpUrl(item.poster?.toString());
                final backdrop = _coerceHttpUrl(meta?.backdrop);
                final resolvedMediaSignature = [
                  tmdbId,
                  snap.connectionState.name,
                  isLoadingMeta,
                  posterBackground,
                  poster,
                  backdrop,
                ].join('|');
                if (_lastLoggedResolvedMediaSignature !=
                    resolvedMediaSignature) {
                  _lastLoggedResolvedMediaSignature = resolvedMediaSignature;
                  _logHeroDebug(
                    'future_builder_state',
                    context: <String, Object?>{
                      'tmdbId': tmdbId,
                      'connectionState': snap.connectionState.name,
                      'isLoadingMeta': isLoadingMeta,
                      'hasMeta': meta != null,
                      'posterBackground': posterBackground,
                      'poster': poster,
                      'backdrop': backdrop,
                    },
                  );
                }

                Widget buildBackground() {
                  final image = Stack(
                    fit: StackFit.expand,
                    children: [
                      MoviHeroBackground(
                        key: ValueKey(
                          '${posterBackground ?? ''}|${poster ?? ''}|${backdrop ?? ''}',
                        ),
                        posterBackground: posterBackground,
                        poster: poster,
                        backdrop: backdrop,
                        placeholderType: item.type == ContentType.series
                            ? PlaceholderType.series
                            : PlaceholderType.movie,
                      ),
                      IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  );

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

                final bool hasTitle = meta?.title?.isNotEmpty ?? false;
                final String displayTitle = hasTitle
                    ? meta!.title!
                    : item.title.value;
                final String? logoUrl = _coerceHttpUrl(meta?.logo);
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
                final String? durationText = isTv
                    ? null
                    : _formatDuration(meta?.runtime);
                final int? seasons = meta?.seasons;
                final String? seasonsText =
                    (isTv && seasons != null && seasons > 0)
                    ? '$seasons ${seasons == 1 ? AppLocalizations.of(context)!.playlistSeasonSingular : AppLocalizations.of(context)!.playlistSeasonPlural}'
                    : null;

                if (isWideHero) {
                  return _buildWideHeroScene(
                    context: context,
                    tmdbId: tmdbId,
                    displayTitle: displayTitle,
                    hasTitle: hasTitle,
                    logoUrl: logoUrl,
                    year: year,
                    yearText: yearText,
                    ratingText: ratingText,
                    durationText: durationText,
                    seasonsText: seasonsText,
                    heroHeight: heroHeight,
                    visualBleed: visualBleed,
                    overlaySpec: overlaySpec,
                    heroContentAlignment: heroContentAlignment,
                    iconActionFocusedBackground: iconActionFocusedBackground,
                    background: buildBackground(),
                    meta: meta,
                  );
                }

                return _buildMobileHeroScene(
                  context: context,
                  tmdbId: tmdbId,
                  displayTitle: displayTitle,
                  hasTitle: hasTitle,
                  logoUrl: logoUrl,
                  year: year,
                  yearText: yearText,
                  ratingText: ratingText,
                  durationText: durationText,
                  seasonsText: seasonsText,
                  heroHeight: heroHeight,
                  overlaySpec: overlaySpec,
                  iconActionFocusedBackground: iconActionFocusedBackground,
                  background: buildBackground(),
                  meta: meta,
                );
              },
            ),
    );

    if (isWideHero) {
      return SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: heroBody,
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: heroHeight),
        child: heroBody,
      ),
    );
  }

  Widget _buildWideHeroScene({
    required BuildContext context,
    required int tmdbId,
    required String displayTitle,
    required bool hasTitle,
    required String? logoUrl,
    required int? year,
    required String yearText,
    required String? ratingText,
    required String? durationText,
    required String? seasonsText,
    required double heroHeight,
    required double visualBleed,
    required MoviHeroOverlaySpec overlaySpec,
    required Alignment heroContentAlignment,
    required Color iconActionFocusedBackground,
    required Widget background,
    required _HeroMeta? meta,
  }) {
    return MoviHeroScene(
      background: background,
      imageHeight: heroHeight,
      overlaySpec: overlaySpec,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).padding.top + 12,
          child: HomeHeroFilterBar(
            moviesFocusNode: widget.moviesFilterFocusNode,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16 + visualBleed,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 50, end: 50),
            child: Align(
              alignment: Alignment(
                heroContentAlignment.x,
                Alignment.bottomCenter.y,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _HeroTextScope(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: _fade,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...previous, if (current != null) current],
                        ),
                        child: Semantics(
                          header: true,
                          label: displayTitle,
                          child: logoUrl == null
                              ? Text(
                                  displayTitle,
                                  key: ValueKey(
                                    hasTitle
                                        ? '${tmdbId}_title_wide'
                                        : '${tmdbId}_titleFallback_wide',
                                  ),
                                  textAlign: TextAlign.left,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              : MoviResponsiveLogo(
                                  imageUrl: logoUrl,
                                  semanticLabel: displayTitle,
                                  alignment: Alignment.centerLeft,
                                  maxWidth: 520,
                                  reservedHeight: 60,
                                  wideMaxHeight: 60,
                                  tallMaxHeight: 104,
                                  blockyMaxHeight: 132,
                                  blockyRatioThreshold: 1.45,
                                  onErrorFallback: (_) => Text(
                                    displayTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHeroPills(
                        tmdbId: tmdbId,
                        year: year,
                        yearText: yearText,
                        ratingText: ratingText,
                        durationText: durationText,
                        seasonsText: seasonsText,
                        centered: false,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 72,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            meta?.overview ?? '',
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
                      ),
                      const SizedBox(height: 16),
                      _buildHeroActionsRow(
                        context: context,
                        iconActionFocusedBackground:
                            iconActionFocusedBackground,
                        primaryButtonWidth: 320,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeroScene({
    required BuildContext context,
    required int tmdbId,
    required String displayTitle,
    required bool hasTitle,
    required String? logoUrl,
    required int? year,
    required String yearText,
    required String? ratingText,
    required String? durationText,
    required String? seasonsText,
    required double heroHeight,
    required MoviHeroOverlaySpec overlaySpec,
    required Color iconActionFocusedBackground,
    required Widget background,
    required _HeroMeta? meta,
  }) {
    final mobileTextWidth = MediaQuery.of(context).size.width * 0.8;
    final Widget synopsis = SizedBox(
      width: mobileTextWidth,
      child: (meta?.overview?.isNotEmpty ?? false)
          ? AnimatedSwitcher(
              duration: _fade,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildSynopsis(
                key: ValueKey('${tmdbId}_synopsis'),
                overview: meta!.overview!,
                tmdbId: tmdbId,
                horizontalPadding: 0,
              ),
            )
          : SizedBox(height: _synopsisHeight, child: const SizedBox.shrink()),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Evite les overflows en mode mobile lorsque le parent contraint la
        // hauteur totale du hero (cas observé sur Windows desktop compact).
        const mobileBottomSectionMinHeight = 180.0;
        double resolvedHeroHeight = heroHeight;
        if (constraints.hasBoundedHeight) {
          final availableForHero =
              constraints.maxHeight - mobileBottomSectionMinHeight;
          resolvedHeroHeight = availableForHero.clamp(260.0, heroHeight);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: resolvedHeroHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(child: background),
                  Positioned.fill(
                    child: MoviHeroOverlays(
                      imageHeight: resolvedHeroHeight,
                      spec: overlaySpec,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: HomeLayoutConstants.heroMobileTopActionsTopInset,
                    child: HomeHeroFilterBar(
                      moviesFocusNode: widget.moviesFilterFocusNode,
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: HomeLayoutConstants.heroMobileContentBottomInset,
                    child: _HeroTextScope(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMobileHeroLogo(
                            tmdbId: tmdbId,
                            displayTitle: displayTitle,
                            hasTitle: hasTitle,
                            logoUrl: logoUrl,
                          ),
                          const SizedBox(height: 16),
                          _buildHeroPills(
                            tmdbId: tmdbId,
                            year: year,
                            yearText: yearText,
                            ratingText: ratingText,
                            durationText: durationText,
                            seasonsText: seasonsText,
                            centered: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  16,
                  AppSpacing.lg,
                  HomeLayoutConstants.heroMobileContentBottomInset,
                ),
                child: _HeroTextScope(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      synopsis,
                      const SizedBox(height: 16),
                      _buildHeroActionsRow(
                        context: context,
                        iconActionFocusedBackground:
                            iconActionFocusedBackground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileHeroLogo({
    required int tmdbId,
    required String displayTitle,
    required bool hasTitle,
    required String? logoUrl,
  }) {
    return AnimatedSwitcher(
      duration: _fade,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, if (current != null) current],
      ),
      child: Semantics(
        header: true,
        label: displayTitle,
        child: FractionallySizedBox(
          widthFactor: HomeLayoutConstants.heroMobileLogoWidthFactor,
          child: SizedBox(
            height: HomeLayoutConstants.heroMobileLogoHeight,
            child: Center(
              child: logoUrl == null
                  ? Text(
                      displayTitle,
                      key: ValueKey(
                        hasTitle
                            ? '${tmdbId}_title_mobile'
                            : '${tmdbId}_titleFallback_mobile',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : MoviNetworkImage(
                      logoUrl,
                      key: ValueKey('${tmdbId}_logo_mobile'),
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      cacheWidth: 900,
                      errorBuilder: (_, __, ___) => Text(
                        displayTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPills({
    required int tmdbId,
    required int? year,
    required String yearText,
    required String? ratingText,
    required String? durationText,
    required String? seasonsText,
    required bool centered,
  }) {
    const heroPillBackground = Color(0x80383838);
    final List<Widget> pills = [
      if (durationText != null)
        MoviPill(durationText, large: true, color: heroPillBackground),
      if (seasonsText != null)
        MoviPill(seasonsText, large: true, color: heroPillBackground),
      if (year != null)
        MoviPill(yearText, large: true, color: heroPillBackground),
      if (ratingText != null)
        MoviPill(
          ratingText,
          trailingIcon: const MoviAssetIcon(
            AppAssets.iconStarFilled,
            width: 18,
            height: 18,
            color: AppColors.ratingAccent,
          ),
          large: true,
          color: heroPillBackground,
        ),
    ];

    return AnimatedSwitcher(
      duration: _fade,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      layoutBuilder: (current, previous) => Stack(
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        children: [...previous, if (current != null) current],
      ),
      child: Wrap(
        key: ValueKey('${tmdbId}_${centered ? 'centered' : 'wide'}_pills'),
        spacing: 8,
        runSpacing: 8,
        alignment: centered ? WrapAlignment.center : WrapAlignment.start,
        children: pills,
      ),
    );
  }

  Widget _buildHeroActionsRow({
    required BuildContext context,
    required Color iconActionFocusedBackground,
    double? primaryButtonWidth,
  }) {
    final Widget primaryButton = Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handlePrimaryActionKey(event),
      child: MoviPrimaryButton(
        label: AppLocalizations.of(context)!.homeWatchNow,
        focusNode: widget.primaryActionFocusNode,
        assetIcon: AppAssets.iconPlay,
        onPressed: () => _openDetails(context),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: primaryButtonWidth == null
          ? MainAxisSize.max
          : MainAxisSize.min,
      children: [
        if (primaryButtonWidth == null)
          Expanded(child: primaryButton)
        else
          SizedBox(width: primaryButtonWidth, child: primaryButton),
        const SizedBox(width: 16),
        Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleFavoriteActionKey(event),
          child: Consumer(
            builder: (context, ref, _) => _buildFavoriteActionButton(
              context: context,
              ref: ref,
              iconActionFocusedBackground: iconActionFocusedBackground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required Color iconActionFocusedBackground,
  }) {
    final current = _currentItem;
    if (current == null) {
      return _buildFavoritePlaceholderButton(
        context: context,
        iconActionFocusedBackground: iconActionFocusedBackground,
      );
    }
    final id = current.id.trim();
    if (id.isEmpty) {
      return _buildFavoritePlaceholderButton(
        context: context,
        iconActionFocusedBackground: iconActionFocusedBackground,
      );
    }

    if (current.type == ContentType.series) {
      final isFavoriteAsync = ref.watch(tvIsFavoriteProvider(id));
      return isFavoriteAsync.when(
        data: (isFavorite) => _buildFavoriteResolvedButton(
          context: context,
          iconActionFocusedBackground: iconActionFocusedBackground,
          isFavorite: isFavorite,
          onPressed: () async {
            await ref.read(tvToggleFavoriteProvider.notifier).toggle(id);
          },
        ),
        loading: () => _buildFavoritePlaceholderButton(
          context: context,
          iconActionFocusedBackground: iconActionFocusedBackground,
        ),
        error: (_, __) => _buildFavoritePlaceholderButton(
          context: context,
          iconActionFocusedBackground: iconActionFocusedBackground,
        ),
      );
    }

    final isFavoriteAsync = ref.watch(movieIsFavoriteProvider(id));
    return isFavoriteAsync.when(
      data: (isFavorite) => _buildFavoriteResolvedButton(
        context: context,
        iconActionFocusedBackground: iconActionFocusedBackground,
        isFavorite: isFavorite,
        onPressed: () async {
          await ref.read(movieToggleFavoriteProvider.notifier).toggle(id);
        },
      ),
      loading: () => _buildFavoritePlaceholderButton(
        context: context,
        iconActionFocusedBackground: iconActionFocusedBackground,
      ),
      error: (_, __) => _buildFavoritePlaceholderButton(
        context: context,
        iconActionFocusedBackground: iconActionFocusedBackground,
      ),
    );
  }

  Widget _buildFavoriteResolvedButton({
    required BuildContext context,
    required Color iconActionFocusedBackground,
    required bool isFavorite,
    required Future<void> Function() onPressed,
  }) {
    return MoviFavoriteButton(
      isFavorite: isFavorite,
      size: 44,
      iconSize: 28,
      focusPadding: const EdgeInsets.all(5),
      focusedBackgroundColor: iconActionFocusedBackground,
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      borderWidth: 2,
      onPressed: () => unawaited(onPressed()),
    );
  }

  Widget _buildFavoritePlaceholderButton({
    required BuildContext context,
    required Color iconActionFocusedBackground,
  }) {
    return MoviFavoriteButton(
      isFavorite: false,
      size: 44,
      iconSize: 28,
      focusPadding: const EdgeInsets.all(5),
      focusedBackgroundColor: iconActionFocusedBackground,
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      borderWidth: 2,
      onPressed: () {},
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    final current = _currentItem;
    if (current == null) return;

    final id = current.id.trim();
    if (id.isEmpty) return;

    if (!mounted || !context.mounted) return;

    _suspendBackgroundWork(reason: 'open_details');
    unawaited(_hydrateMetaFull(current));

    try {
      if (current.type == ContentType.series) {
        await navigateToTvDetail(
          context,
          ref,
          ContentRouteArgs.series(id),
          originRegionId: AppFocusRegionId.homePrimary,
          fallbackRegionId: AppFocusRegionId.homePrimary,
        );
        return;
      }

      await navigateToMovieDetail(
        context,
        ref,
        ContentRouteArgs.movie(id),
        originRegionId: AppFocusRegionId.homePrimary,
        fallbackRegionId: AppFocusRegionId.homePrimary,
      );
    } finally {
      if (mounted) {
        _resumeBackgroundWork(reason: 'details_closed');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Pré-chargement images
  // ---------------------------------------------------------------------------

  void _precacheBgFor(
    ContentReference item, {
    required bool isNext,
    required int workToken,
  }) {
    if (!_canRunBackgroundWork) return;
    final int? id = _tmdbIdOf(item);
    if (id == null) return;
    if (_disableHeroPrecacheOnCurrentPlatform) {
      _diagnostics.mark(
        'home_hero_precache_image',
        event: 'skipped',
        context: <String, Object?>{
          'tmdbId': id,
          'isNext': isNext,
          'reason': 'platform_disabled',
          'strategy': 'windows_precache_disabled',
        },
      );
      return;
    }
    if (_precachedBgIds.contains(id)) return;

    final Future<_HeroMeta?>? future = _metaFutures[id];
    if (future == null) return;

    future.then((meta) async {
      if (!_isCurrentHeroItemToken(workToken, tmdbId: id, isNext: isNext)) {
        return;
      }
      if (isNext) {
        final int? currentId = _tmdbIdOf(_currentItem);
        if (currentId == null || !_precachedBgIds.contains(currentId)) {
          _diagnostics.mark(
            'home_hero_precache_image',
            event: 'skipped',
            context: <String, Object?>{
              'tmdbId': id,
              'isNext': isNext,
              'reason': 'current_not_precached',
              'currentTmdbId': currentId,
            },
          );
          return;
        }
      }
      if (_activePrecacheId != null && _activePrecacheId != id) {
        _diagnostics.mark(
          'home_hero_precache_image',
          event: 'skipped',
          context: <String, Object?>{
            'tmdbId': id,
            'isNext': isNext,
            'reason': 'another_precache_active',
            'activeTmdbId': _activePrecacheId,
          },
        );
        return;
      }

      final String? bgSrc =
          _coerceHttpUrl(meta?.precachePosterBg) ??
          _coerceHttpUrl(meta?.precachePoster) ??
          _coerceHttpUrl(meta?.precacheBackdrop) ??
          _coerceHttpUrl(meta?.posterBg) ??
          _coerceHttpUrl(meta?.poster) ??
          _coerceHttpUrl(item.poster?.toString()) ??
          _coerceHttpUrl(meta?.backdrop);

      if (bgSrc == null) return;

      final stopwatch = Stopwatch()..start();
      try {
        _activePrecacheId = id;
        if (!mounted || !context.mounted) {
          _logHeroAbandoned(
            'home_hero_precache_image',
            stopwatch: stopwatch,
            context: <String, Object?>{
              'tmdbId': id,
              'isNext': isNext,
              'reason': 'widget_not_mounted',
              'strategy': 'bounded_tmdb_size',
            },
          );
          return;
        }
        await precacheImage(NetworkImage(bgSrc), context).timeout(
          _heroPrecacheTimeout,
          onTimeout: () =>
              throw TimeoutException('Hero precache timed out for tmdbId=$id'),
        );
        if (!_isCurrentHeroItemToken(workToken, tmdbId: id, isNext: isNext)) {
          _logHeroAbandoned(
            'home_hero_precache_image',
            stopwatch: stopwatch,
            context: <String, Object?>{
              'tmdbId': id,
              'isNext': isNext,
              'reason': 'current_item_changed_after_precache',
              'strategy': 'bounded_tmdb_size',
            },
          );
          return;
        }
        _precachedBgIds.add(id);
        _diagnostics.completed(
          'home_hero_precache_image',
          elapsed: stopwatch.elapsed,
          context: <String, Object?>{
            'tmdbId': id,
            'isNext': isNext,
            'strategy': 'bounded_tmdb_size',
          },
        );
      } catch (e, st) {
        final isTimeout = e is TimeoutException;
        _diagnostics.failed(
          'home_hero_precache_image',
          elapsed: stopwatch.elapsed,
          error: e,
          stackTrace: st,
          context: <String, Object?>{
            'tmdbId': id,
            'isNext': isNext,
            'strategy': 'bounded_tmdb_size',
            'reason': isTimeout ? 'timeout' : 'error',
            if (isTimeout) 'timeoutMs': _heroPrecacheTimeout.inMilliseconds,
          },
        );
        if (kDebugMode) {
          debugPrint('HomeHeroCarousel: precache failed for $id: $e\n$st');
        }
      } finally {
        _releasePrecacheLock(id);
        if (!isNext &&
            _isCurrentHeroItemToken(workToken, tmdbId: id, isNext: false)) {
          final tuning = ref.read(performanceTuningProvider);
          final ContentReference? next = _nextItem;
          final int? nextId = _tmdbIdOf(next);
          if (tuning.homeHeroPrecacheNextImage &&
              next != null &&
              nextId != null &&
              !_precachedBgIds.contains(nextId)) {
            _precacheBgFor(next, isNext: true, workToken: workToken);
          }
        }
        _retryCurrentHeroPreparationIfNeeded(completedTmdbId: id);
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
    double horizontalPadding = AppSpacing.lg,
  }) {
    final bool isExpanded = _synopsisExpanded[tmdbId] ?? false;

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth - (AppSpacing.lg * 2);
        final bool needsExpansion = _needsExpansion(overview, maxWidth);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: _HeroTextScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topLeft,
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

class _HeroTextScope extends StatelessWidget {
  const _HeroTextScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: const TextStyle(decoration: TextDecoration.none),
        child: child,
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
    this.precachePosterBg,
    this.precachePoster,
    this.precacheBackdrop,
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
  final String? precachePosterBg;
  final String? precachePoster;
  final String? precacheBackdrop;
  final String? logo;
  final String? title;
  final String? overview;
  final int? year;
  final double? rating;
  final int? runtime;
  final int? seasons;
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({required this.heroHeight, required this.isWideHero});
  final double heroHeight;
  final bool isWideHero;

  @override
  Widget build(BuildContext context) {
    final overlaySpec = MoviHeroOverlaySpec.homeBottomOnly(
      isWideLayout: isWideHero,
    );

    if (isWideHero) {
      return Column(
        children: [
          Expanded(
            child: MoviHeroScene(
              background: const ColoredBox(color: Color(0xFF222222)),
              imageHeight: heroHeight,
              overlaySpec: overlaySpec,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).padding.top + 12,
                  child: const HomeHeroFilterBar(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: HomeLayoutConstants.heroMobileContentBottomInset,
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
                            return MoviAssetIcon(
                              AppAssets.iconAppLogoSvg,
                              color: accentColor,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: MoviHeroScene(
                  background: const ColoredBox(color: Color(0xFF222222)),
                  imageHeight: heroHeight,
                  overlaySpec: overlaySpec,
                  children: const [],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: HomeLayoutConstants.heroMobileTopActionsTopInset,
                child: const HomeHeroFilterBar(),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: HomeLayoutConstants.heroMobileContentBottomInset,
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
                          return MoviAssetIcon(
                            AppAssets.iconAppLogoSvg,
                            color: accentColor,
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
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              16,
              AppSpacing.lg,
              HomeLayoutConstants.heroMobileContentBottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 80),
                SizedBox(height: 16),
                Row(children: [Expanded(child: SizedBox(height: 48))]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroEmpty extends StatelessWidget {
  const _HeroEmpty({required this.heroHeight, required this.isWideHero});
  final double heroHeight;
  final bool isWideHero;

  @override
  Widget build(BuildContext context) {
    final overlaySpec = MoviHeroOverlaySpec.homeBottomOnly(
      isWideLayout: isWideHero,
    );

    if (isWideHero) {
      return Column(
        children: [
          Expanded(
            child: MoviHeroScene(
              background: const ColoredBox(color: Color(0xFF222222)),
              imageHeight: heroHeight,
              overlaySpec: overlaySpec,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).padding.top + 12,
                  child: const HomeHeroFilterBar(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: HomeLayoutConstants.heroMobileContentBottomInset,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: MoviHeroScene(
                  background: const ColoredBox(color: Color(0xFF222222)),
                  imageHeight: heroHeight,
                  overlaySpec: overlaySpec,
                  children: const [],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: HomeLayoutConstants.heroMobileTopActionsTopInset,
                child: const HomeHeroFilterBar(),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: HomeLayoutConstants.heroMobileContentBottomInset,
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
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              16,
              AppSpacing.lg,
              HomeLayoutConstants.heroMobileContentBottomInset,
            ),
            child: Row(children: [Expanded(child: SizedBox(height: 48))]),
          ),
        ),
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
