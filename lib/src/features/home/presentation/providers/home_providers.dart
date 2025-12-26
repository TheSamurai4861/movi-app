// lib/src/features/home/presentation/providers/home_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/performance/providers/performance_providers.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/home/domain/usecases/load_continue_watching_media.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_hero.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_iptv_sections.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/home/domain/entities/in_progress_media.dart'
    as domain;
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';

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

enum HomeIptvMediaFilter { all, movies, series }

class HomeIptvMediaFilterController extends Notifier<HomeIptvMediaFilter> {
  @override
  HomeIptvMediaFilter build() => HomeIptvMediaFilter.all;

  void set(HomeIptvMediaFilter filter) {
    state = filter;
  }

  void toggle(HomeIptvMediaFilter filter) {
    state = state == filter ? HomeIptvMediaFilter.all : filter;
  }
}

final homeIptvMediaFilterProvider =
    NotifierProvider<HomeIptvMediaFilterController, HomeIptvMediaFilter>(
  HomeIptvMediaFilterController.new,
);

/// État immutable du Home.
class HomeState {
  const HomeState({
    this.hero = const <ContentReference>[],
    this.cwMovies = const <MovieSummary>[],
    this.cwShows = const <TvShowSummary>[],
    this.iptvLists = const <String, List<ContentReference>>{},
    this.isLoading = false,
    this.isHeroEmpty = false,
    this.error,
  });

  final List<ContentReference> hero;
  final List<MovieSummary> cwMovies;
  final List<TvShowSummary> cwShows;
  final Map<String, List<ContentReference>> iptvLists;
  final bool isLoading;
  final bool isHeroEmpty;
  final String? error;

  static const _sentinel = Object();

  /// copyWith qui permet aussi de *forcer* error à null.
  HomeState copyWith({
    List<ContentReference>? hero,
    List<MovieSummary>? cwMovies,
    List<TvShowSummary>? cwShows,
    Map<String, List<ContentReference>>? iptvLists,
    bool? isLoading,
    bool? isHeroEmpty,
    Object? error = _sentinel,
  }) {
    return HomeState(
      hero: hero ?? this.hero,
      cwMovies: cwMovies ?? this.cwMovies,
      cwShows: cwShows ?? this.cwShows,
      iptvLists: iptvLists ?? this.iptvLists,
      isLoading: isLoading ?? this.isLoading,
      isHeroEmpty: isHeroEmpty ?? this.isHeroEmpty,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

class _HomeRefreshRequest {
  const _HomeRefreshRequest({
    required this.awaitIptv,
    required this.reason,
    required this.force,
    required this.cooldown,
  });

  final bool awaitIptv;
  final String reason;
  final bool force;
  final Duration? cooldown;
}

/// Contrôleur Home avec enrichissement batché + annulation propre.
class HomeController extends Notifier<HomeState> {
  HomeFeedRepository? _repo;
  LoadHomeHero? _loadHero;
  LoadHomeIptvSections? _loadIptv;
  StreamSubscription<AppEvent>? _eventSub;
  _HomeRefreshRequest? _queuedRefresh;
  bool _profileListenerAttached = false;
  bool _cwListenerAttached = false;
  DateTime? _lastRefreshAt;
  String _lastRefreshReason = 'unknown';

  static const Duration _defaultRefreshCooldown = Duration(seconds: 10);

  /// Builds hero for kid profiles by paginating through trending and filtering by age.
  /// Returns up to 8 movies and 8 series that are age-appropriate.
  Future<List<ContentReference>> _buildKidHeroFromTrending(
    List<ContentReference> initialHero,
    Profile profile,
    parental.AgePolicy policy,
  ) async {
    const int targetMovies = 8;
    const int targetSeries = 8;
    const int maxPages = 10;

    if (_repo == null) {
      // Fallback: filter what we have
      return await policy.filterAllowed(initialHero, profile);
    }

    // Separate movies and series from initial hero
    final initialMovies = initialHero
        .where((e) => e.type == ContentType.movie)
        .toList(growable: false);
    final initialSeries = initialHero
        .where((e) => e.type == ContentType.series)
        .toList(growable: false);

    // Collect all movies by paginating if needed
    final allMovies = <ContentReference>[...initialMovies];
    var allowedMovies = await policy.filterAllowedUpTo(
      allMovies,
      profile,
      limit: targetMovies,
    );

    if (allowedMovies.length < targetMovies) {
      var currentPage = 2; // Start from page 2 since page 1 is already in initialHero
      while (allowedMovies.length < targetMovies && currentPage <= maxPages) {
        final pageResult = await _repo!.getTrendingMoviesPage(currentPage);
        final pageMovies = pageResult.fold(
          ok: (movies) => movies,
          err: (_) => <ContentReference>[],
        );

        if (pageMovies.isEmpty) {
          // No more pages available
          break;
        }

        allMovies.addAll(pageMovies);

        // Re-filter with all collected movies
        allowedMovies = await policy.filterAllowedUpTo(
          allMovies,
          profile,
          limit: targetMovies,
        );

        currentPage++;
      }
    }

    // Collect all series by paginating if needed
    final allSeries = <ContentReference>[...initialSeries];
    var allowedSeries = await policy.filterAllowedUpTo(
      allSeries,
      profile,
      limit: targetSeries,
    );

    if (allowedSeries.length < targetSeries) {
      var currentPage = 2; // Start from page 2 since page 1 is already in initialHero
      while (allowedSeries.length < targetSeries && currentPage <= maxPages) {
        final pageResult = await _repo!.getTrendingSeriesPage(currentPage);
        final pageSeries = pageResult.fold(
          ok: (series) => series,
          err: (_) => <ContentReference>[],
        );

        if (pageSeries.isEmpty) {
          // No more pages available
          break;
        }

        allSeries.addAll(pageSeries);

        // Re-filter with all collected series
        allowedSeries = await policy.filterAllowedUpTo(
          allSeries,
          profile,
          limit: targetSeries,
        );

        currentPage++;
      }
    }

    // Interleave movies and series
    return _interleaveMoviesAndSeries(allowedMovies, allowedSeries);
  }

  List<ContentReference> _interleaveMoviesAndSeries(
    List<ContentReference> movies,
    List<ContentReference> series,
  ) {
    if (movies.isEmpty) return series;
    if (series.isEmpty) return movies;

    final out = <ContentReference>[];
    final maxLen = (movies.length > series.length) ? movies.length : series.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < movies.length) out.add(movies[i]);
      if (i < series.length) out.add(series[i]);
    }
    return out;
  }

  // Deprecated: No longer used for hero building (replaced by _buildKidHeroFromTrending)
  // Kept for potential future use
  // List<ContentReference> _buildKidHeroFromIptv(
  //   Map<String, List<ContentReference>> iptv, {
  //   int limit = 20,
  // }) {
  //   if (iptv.isEmpty || limit <= 0) return const <ContentReference>[];

  //   // Mix: round-robin across categories, movies only, TMDB ids only.
  //   final lists = <List<ContentReference>>[];
  //   for (final entry in iptv.entries) {
  //     final movies = entry.value
  //         .where((e) => e.type == ContentType.movie)
  //         .where((e) => int.tryParse(e.id.trim()) != null)
  //         .toList(growable: false);
  //     if (movies.isNotEmpty) lists.add(movies);
  //   }
  //   if (lists.isEmpty) return const <ContentReference>[];

  //   final cursors = List<int>.filled(lists.length, 0);
  //   final out = <ContentReference>[];
  //   final seen = <String>{};

  //   var any = true;
  //   while (out.length < limit && any) {
  //     any = false;
  //     for (var i = 0; i < lists.length; i++) {
  //       if (out.length >= limit) break;
  //       final list = lists[i];
  //       var cursor = cursors[i];
  //       if (cursor >= list.length) continue;

  //       // Advance cursor until we find a non-duplicate (or list end).
  //       while (cursor < list.length) {
  //         final item = list[cursor];
  //         cursor += 1;
  //         if (seen.add('${item.type.name}:${item.id}')) {
  //           out.add(item);
  //           any = true;
  //           break;
  //         }
  //       }
  //       cursors[i] = cursor;
  //     }
  //   }

  //   return out;
  // }

  @override
  HomeState build() {
    // (Re)bind si besoin.
    final r = ref.watch(homeFeedRepositoryProvider);
    if (!identical(_repo, r)) {
      _repo = r;
      _loadHero = LoadHomeHero(r);
      _loadIptv = LoadHomeIptvSections(r);
    }

    if (_eventSub == null) {
      final bus = ref.watch(appEventBusProvider);
      _eventSub = bus.stream.listen((event) {
        if (event.type == AppEventType.iptvSynced ||
            event.type == AppEventType.librarySynced) {
          final reason = event.type == AppEventType.iptvSynced
              ? 'iptvSynced'
              : 'librarySynced';
          unawaited(
            load(
              reason: reason,
              cooldown: _defaultRefreshCooldown,
            ),
          );
        }
      });

      ref.onDispose(() {
        _eventSub?.cancel();
        _eventSub = null;
      });
    }

    if (!_profileListenerAttached) {
      _profileListenerAttached = true;
      // Ensure Home updates (hero + filtering) when switching profiles or when profile becomes available.
      ref.listen(currentProfileProvider, (previous, next) {
        // Reload if profile becomes available (null -> non-null) or if profile properties change
        final shouldReload = previous == null && next != null ||
            (previous != null && next != null &&
                (previous.id != next.id ||
                    previous.isKid != next.isKid ||
                    previous.pegiLimit != next.pegiLimit));
        if (shouldReload) {
          if (_shouldSkipProfileChangeDuringBootstrap()) {
            _logRefreshDecision(
              reason: 'profileChange',
              action: 'skip',
              detail: 'preload_inflight',
            );
            return;
          }
          unawaited(
            load(
              reason: 'profileChange',
              force: true,
            ),
          );
        }
      });
    }

    if (!_cwListenerAttached) {
      _cwListenerAttached = true;
      ref.listen<AsyncValue<List<domain.InProgressMedia>>>(
        homeInProgressProvider,
        (previous, next) {
          next.whenData((items) {
            final movies = _mapCwMovies(items);
            final shows = _mapCwShows(items);
            state = state.copyWith(cwMovies: movies, cwShows: shows);
          });
        },
        fireImmediately: true,
      );
    }

    return const HomeState();
  }

  Future<void> load({
    bool awaitIptv = false,
    String reason = 'unknown',
    bool force = false,
    Duration? cooldown,
  }) async {
    final startedAt = DateTime.now();
    final now = startedAt;
    final effectiveCooldown = cooldown ?? _defaultRefreshCooldown;
    _logHomeLoadCycle(
      action: 'start',
      reason: reason,
      force: force,
      cooldown: effectiveCooldown,
    );
    final lastRefreshAt = _lastRefreshAt;

    if (!force && lastRefreshAt != null) {
      final elapsed = now.difference(lastRefreshAt);
      if (elapsed < effectiveCooldown) {
        _logRefreshDecision(
          reason: reason,
          action: 'skip',
          detail: 'cooldown',
        );
        _logHomeLoadCycle(
          action: 'end',
          reason: reason,
          force: force,
          cooldown: effectiveCooldown,
          result: 'skip',
          duration: DateTime.now().difference(startedAt),
          detail: 'cooldown',
        );
        return;
      }
    }

    if (state.isLoading) {
      _queuedRefresh = _HomeRefreshRequest(
        awaitIptv: awaitIptv,
        reason: reason,
        force: force,
        cooldown: cooldown,
      );
      _logRefreshDecision(
        reason: reason,
        action: 'queue',
        detail: 'loading',
      );
      _logHomeLoadCycle(
        action: 'end',
        reason: reason,
        force: force,
        cooldown: effectiveCooldown,
        result: 'queue',
        duration: DateTime.now().difference(startedAt),
        detail: 'loading',
      );
      return;
    }

    _lastRefreshAt = now;
    _lastRefreshReason = reason;
    _logRefreshDecision(reason: reason, action: 'run');

    // Toujours “safe”: ne jamais throw (le bootstrap ne doit pas exploser sur Home).
    state = state.copyWith(isLoading: true, error: null);

    final tuning = ref.read(performanceTuningProvider);
    final profile = ref.read(currentProfileProvider);
    final bool isKid = profile?.isKid == true;
    final bool hasRestrictions =
        profile != null && (profile.isKid || profile.pegiLimit != null);
    // Fetch more items per playlist when restricted so we can "fill" sections
    // after filtering without showing an almost empty row.
    final int iptvFetchLimit = hasRestrictions
        ? HomeLayoutConstants.iptvSectionLimit * 12
        : HomeLayoutConstants.iptvSectionLimit;

    // Debug: on peut couper le Hero (et ses appels TMDB) via feature flag
    // pour isoler un crash lié au carrousel/enrichissement.
    final bool disableHero = ref.read(featureFlagsProvider).home.disableHero;

    List<ContentReference> hero = const <ContentReference>[];
    Map<String, List<ContentReference>> iptv =
        const <String, List<ContentReference>>{};
    String? error;

    // 1) Première passe: hero + iptv
    Object? heroResult;
    Object? iptvResult;

    // For restricted profiles, Home content must be filtered; do not defer IPTV.
    // For kid profiles, the hero is built from allowed IPTV movies, so do not defer either.
    final bool deferIptv = !hasRestrictions && tuning.isLowResources && !awaitIptv;

    // Charger hero et IPTV en parallèle (chacun reste "safe").
    final futures = <Future<void>>[];

    // Load trending hero for all profiles (including kids, but kids will filter by age)
    if (!disableHero) {
      futures.add(
        Future<void>(() async {
          try {
            heroResult = await _loadHero!.call();
          } catch (e) {
            error ??= e.toString();
            heroResult = null;
          }
        }),
      );
    }

    if (!deferIptv) {
      futures.add(
        Future<void>(() async {
          try {
            iptvResult = await _loadIptv!.call(itemLimitPerPlaylist: iptvFetchLimit);
          } catch (e) {
            error ??= e.toString();
            iptvResult = null;
          }
        }),
      );
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // Interprétation des résultats (Result.fold), mais sans dépendre d’un type précis
    // si jamais une exception a été catch.
    if (heroResult != null) {
      try {
        // ignore: avoid_dynamic_calls
        (heroResult as dynamic).fold(
          ok: (value) => hero = (value as List<ContentReference>),
          err: (failure) => error ??= (failure as dynamic).message as String?,
        );
      } catch (e) {
        error ??= e.toString();
      }
    }

    if (iptvResult != null) {
      try {
        // ignore: avoid_dynamic_calls
        (iptvResult as dynamic).fold(
          ok: (value) =>
              iptv = (value as Map<String, List<ContentReference>>),
          err: (failure) => error ??= (failure as dynamic).message as String?,
        );
      } catch (e) {
        error ??= e.toString();
      }
    }

    if (hasRestrictions) {
      final policy = ref.read(parental.agePolicyProvider);
      final classifier = ref.read(slProvider)<parental.PlaylistMaturityClassifier>();
      final effectivePegi = parental.PegiRating.tryParse(profile.pegiLimit) ??
          (profile.isKid ? parental.PegiRating.pegi12 : null);

      // Filtrer uniquement par titre de playlist (ex: horreur) pour les profils enfants
      // Les items individuels ne sont plus filtrés ici, la protection se fait à la navigation
      if (effectivePegi != null && iptv.isNotEmpty) {
        final filtered = <String, List<ContentReference>>{};
        for (final entry in iptv.entries) {
          final required = classifier.requiredPegiForPlaylistTitle(entry.key);
          if (required != null && effectivePegi.value < required) {
            continue;
          }
          // Limiter le nombre d'items affichés mais ne pas filtrer par âge
          final limited = entry.value
              .take(HomeLayoutConstants.iptvSectionLimit)
              .toList(growable: false);
          if (limited.isNotEmpty) {
            filtered[entry.key] = limited;
          }
        }
        iptv = filtered;
      }

      // Hero filtering: for adult restricted profiles we filter Trending hero;
      // for kid profiles we paginate through trending and filter by age.
      if (isKid) {
        try {
          hero = await _buildKidHeroFromTrending(hero, profile, policy);
        } catch (_) {
          // Best-effort: fallback to simple filtering if pagination fails
          try {
            hero = await policy.filterAllowed(hero, profile);
          } catch (_) {
            // Don't block home if rating lookups fail
          }
        }
      } else {
        try {
          hero = await policy.filterAllowed(hero, profile);
        } catch (_) {
          // Best-effort: don't block home if rating lookups fail.
        }
      }
    } else if (isKid && profile != null) {
      // Safety: a kid profile should always have restrictions, but if it's
      // misconfigured (no isKid/pegiLimit), still filter trending by age.
      final policy = ref.read(parental.agePolicyProvider);
      try {
        hero = await _buildKidHeroFromTrending(hero, profile, policy);
      } catch (_) {
        // Best-effort: fallback to simple filtering if pagination fails
        try {
          hero = await policy.filterAllowed(hero, profile);
        } catch (_) {
          // Don't block home if rating lookups fail
        }
      }
    }

    state = state.copyWith(
      hero: hero,
      iptvLists: iptv,
      isLoading: deferIptv,
      isHeroEmpty: disableHero ? true : hero.isEmpty,
      error: error,
    );

    if (!deferIptv) {
      _drainQueuedRefresh();
    }

    if (deferIptv) {
      unawaited(
        _loadIptv!.call(itemLimitPerPlaylist: iptvFetchLimit).then((result) {
          Map<String, List<ContentReference>> iptvValue =
              const <String, List<ContentReference>>{};
          String? iptvError;

          try {
            // ignore: avoid_dynamic_calls
            (result as dynamic).fold(
              ok: (value) =>
                  iptvValue = (value as Map<String, List<ContentReference>>),
              err: (failure) =>
                  iptvError ??= (failure as dynamic).message as String?,
            );
          } catch (e) {
            iptvError ??= e.toString();
          }

          state = state.copyWith(
            iptvLists: iptvValue,
            isLoading: false,
            error: iptvError ?? state.error,
          );

          _drainQueuedRefresh();
        }).catchError((e) {
          state = state.copyWith(isLoading: false, error: e.toString());

          _drainQueuedRefresh();
        }),
      );
    }

    _logHomeLoadCycle(
      action: 'end',
      reason: reason,
      force: force,
      cooldown: effectiveCooldown,
      result: error == null ? 'ok' : 'err',
      duration: DateTime.now().difference(startedAt),
      detail: error == null ? null : 'error',
    );
  }

  Future<void> refresh({String reason = 'userAction'}) {
    return load(reason: reason, force: true);
  }

  void _drainQueuedRefresh() {
    final queued = _queuedRefresh;
    if (queued == null) return;
    _queuedRefresh = null;
    unawaited(
      load(
        awaitIptv: queued.awaitIptv,
        reason: queued.reason,
        force: queued.force,
        cooldown: queued.cooldown,
      ),
    );
  }

  void _logRefreshDecision({
    required String reason,
    required String action,
    String? detail,
  }) {
    final ts = DateTime.now().toIso8601String();
    final last = _lastRefreshReason;
    final extra = detail == null ? '' : ' detail=$detail';
    unawaited(
      LoggingService.log(
        '[HomeRefresh] ts=$ts reason=$reason action=$action last=$last$extra',
      ),
    );
  }

  bool _shouldSkipProfileChangeDuringBootstrap() {
    final lastAt = _lastRefreshAt;
    if (lastAt == null) return false;
    if (_lastRefreshReason != 'preload') return false;
    return DateTime.now().difference(lastAt) < _defaultRefreshCooldown;
  }

  void _logHomeLoadCycle({
    required String action,
    required String reason,
    required bool force,
    Duration? cooldown,
    String? result,
    Duration? duration,
    String? detail,
  }) {
    final ts = DateTime.now().toIso8601String();
    final parts = <String>[
      'ts=$ts',
      'action=$action',
      'reason=$reason',
      'force=$force',
      if (cooldown != null) 'cooldown=${cooldown.inMilliseconds}ms',
      if (result != null) 'result=$result',
      if (duration != null) 'duration=${duration.inMilliseconds}ms',
      if (detail != null) 'detail=$detail',
    ];
    unawaited(
      LoggingService.log('[HomeLoad] ${parts.join(' ')}'),
    );
  }

  List<MovieSummary> _mapCwMovies(List<domain.InProgressMedia> items) {
    return items
        .where((e) => e.type == ContentType.movie && e.poster != null)
        .map(
          (e) => MovieSummary(
            id: MovieId(e.contentId),
            title: MediaTitle(e.title),
            poster: e.poster!,
            backdrop: e.backdrop,
            releaseYear: e.year,
            tags: const [],
          ),
        )
        .toList(growable: false);
  }

  List<TvShowSummary> _mapCwShows(List<domain.InProgressMedia> items) {
    return items
        .where((e) => e.type == ContentType.series && e.poster != null)
        .map(
          (e) => TvShowSummary(
            id: SeriesId(e.contentId),
            title: MediaTitle(e.seriesTitle ?? e.title),
            poster: e.poster!,
            backdrop: e.backdrop,
          ),
        )
        .toList(growable: false);
  }
}

final homeFeedRepositoryProvider = Provider<HomeFeedRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<HomeFeedRepository>();
});

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

/// Provider pour charger les médias en cours depuis l'historique.
///
/// La logique métier (progression, enrichissement TMDB, tri) vit dans
/// le use case `LoadContinueWatchingMedia` et son service dédié.
final homeInProgressProvider =
    FutureProvider<List<domain.InProgressMedia>>((ref) async {
  final locator = ref.watch(slProvider);
  final useCase = locator<LoadContinueWatchingMedia>();
  final userId = ref.watch(currentUserIdProvider);

  // Aligner le crit?re "en cours" avec la librairie:
  // - progression >= minProgressThreshold
  // - et < maxProgressThreshold
  return useCase(
    minProgress: HomeLayoutConstants.minProgressThreshold,
    maxProgress: HomeLayoutConstants.maxProgressThreshold,
    userId: userId,
  );
});

/// Provider pour obtenir l'état de lecture d'un média spécifique
final mediaHistoryProvider = FutureProvider.family<
    HistoryEntry?, ({String contentId, ContentType type})>((ref, params) async {
  final locator = ref.watch(slProvider);
  final historyRepo = locator<HistoryLocalRepository>();
  final userId = ref.watch(currentUserIdProvider);

  final entries = await historyRepo.readAll(params.type, userId: userId);

  try {
    final entry = entries.firstWhere((e) => e.contentId == params.contentId);
    if (entry.duration == null || entry.duration!.inSeconds <= 0) {
      return null;
    }

    final pos = entry.lastPosition?.inSeconds ?? 0;
    final progress = pos / entry.duration!.inSeconds;

    // Un média est considéré en cours seulement si la progression est comprise
    // entre les seuils configurés dans HomeLayoutConstants.
    if (progress >= HomeLayoutConstants.minProgressThreshold &&
        progress < HomeLayoutConstants.maxProgressThreshold) {
      return entry;
    }
  } catch (_) {
    // Entry not found
  }

  return null;
});
