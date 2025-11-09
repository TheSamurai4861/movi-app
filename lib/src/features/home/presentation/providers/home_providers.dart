// lib/src/features/home/presentation/providers/home_providers.dart
import 'dart:async'; // unawaited, Future.wait
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injector.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../domain/repositories/home_feed_repository.dart';

class HomeState {
  const HomeState({
    this.hero = const [],
    this.cwMovies = const [],
    this.cwShows = const [],
    this.iptvLists = const {},
    this.isLoading = false,
    this.error,
  });

  final List<MovieSummary> hero;
  final List<MovieSummary> cwMovies;
  final List<TvShowSummary> cwShows;
  final Map<String, List<ContentReference>> iptvLists;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    List<MovieSummary>? hero,
    List<MovieSummary>? cwMovies,
    List<TvShowSummary>? cwShows,
    Map<String, List<ContentReference>>? iptvLists,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      hero: hero ?? this.hero,
      cwMovies: cwMovies ?? this.cwMovies,
      cwShows: cwShows ?? this.cwShows,
      iptvLists: iptvLists ?? this.iptvLists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repo) : super(const HomeState());

  final HomeFeedRepository _repo;

  /// Empêche de relancer l’enrichissement pour les mêmes cartes en parallèle.
  /// Clé = "sectionKey#index"
  final Set<String> _inflight = {};

  /// Plafond de concurrence pour limiter la pression sur TMDB.
  static const int _maxConcurrent = 6;

  /// Chargement prioritaire :
  /// 1) Hero (await) → premier paint rapide
  /// 2) Le reste en arrière-plan (lists & continue watching)
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    // 1) HERO en priorité
    try {
      final hero = await _repo.getHeroMovies();
      state = state.copyWith(hero: hero, isLoading: false);
    } catch (_) {
      // On ne bloque pas l'UI pour autant
      state = state.copyWith(isLoading: false, error: 'Échec du chargement du Hero');
    }

    // 2) Le reste en arrière-plan
    unawaited(() async {
      try {
        final lists = await _repo.getIptvCategoryLists();
        state = state.copyWith(iptvLists: lists);
        // Les sections visibles s’enrichissent ensuite via onViewportChanged.
      } catch (_) {/* no-op */}
    }());

    unawaited(() async {
      try {
        final cwM = await _repo.getContinueWatchingMovies();
        state = state.copyWith(cwMovies: cwM);
      } catch (_) {/* no-op */}
    }());

    unawaited(() async {
      try {
        final cwS = await _repo.getContinueWatchingShows();
        state = state.copyWith(cwShows: cwS);
      } catch (_) {/* no-op */}
    }());
  }

  Future<void> refresh() => load();

  /// Appelée par l’UI quand une section horizontale fait défiler des cartes.
  /// Enrichit les items [start .. start+count-1] s'ils sont encore “légers”.
  /// → Limite la concurrence à [_maxConcurrent] pour éviter une rafale de requêtes.
  Future<void> enrichCategoryBatch(String key, int start, int count) async {
    final list = state.iptvLists[key];
    if (list == null || list.isEmpty) return;
    if (start < 0 || count <= 0) return;

    final end = (start + count - 1).clamp(0, list.length - 1);

    Future<void> _enrichOne(int index, ContentReference ref) async {
      final keyIndex = '$key#$index';
      if (_inflight.contains(keyIndex)) return;
      _inflight.add(keyIndex);
      try {
        final enriched = await _repo.enrichReference(ref);

        // Remplacement immuable dans l’état (section peut avoir bougé entre-temps)
        final current = state.iptvLists[key];
        if (current == null || index >= current.length) return;

        final nextList = List<ContentReference>.from(current);
        nextList[index] = enriched;

        final nextMap = Map<String, List<ContentReference>>.from(state.iptvLists);
        nextMap[key] = nextList;

        state = state.copyWith(iptvLists: nextMap);
      } finally {
        _inflight.remove(keyIndex);
      }
    }

    final futures = <Future<void>>[];

    for (int i = start; i <= end; i++) {
      final ref = list[i];

      // Heuristique "léger" : pas d'année, pas de note, pas de poster TMDB (souvent IPTV)
      final needsEnrich = ref.year == null ||
          ref.rating == null ||
          ref.poster == null ||
          !(ref.poster.toString().contains('image.tmdb.org'));

      if (!needsEnrich) continue;

      futures.add(_enrichOne(i, ref));

      // Plafond de concurrence : on attend dès qu’on atteint le cap
      if (futures.length >= _maxConcurrent) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    // Termine les restes
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}

final homeFeedRepositoryProvider =
    Provider<HomeFeedRepository>((ref) => sl<HomeFeedRepository>());

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.read(homeFeedRepositoryProvider))..load(),
);
