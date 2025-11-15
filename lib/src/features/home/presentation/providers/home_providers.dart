// lib/src/features/home/presentation/providers/home_providers.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_hero.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_continue_watching.dart';
import 'package:movi/src/features/home/domain/usecases/load_home_iptv_sections.dart';

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

/// État immutable du Home.
class HomeState {
  const HomeState({
    this.hero = const <MovieSummary>[],
    this.cwMovies = const <MovieSummary>[],
    this.cwShows = const <TvShowSummary>[],
    this.iptvLists = const <String, List<ContentReference>>{},
    this.isLoading = false,
    this.isHeroEmpty = false,
    this.error,
  });

  final List<MovieSummary> hero;
  final List<MovieSummary> cwMovies;
  final List<TvShowSummary> cwShows;
  final Map<String, List<ContentReference>> iptvLists;
  final bool isLoading;
  final bool isHeroEmpty;
  final String? error;

  HomeState copyWith({
    List<MovieSummary>? hero,
    List<MovieSummary>? cwMovies,
    List<TvShowSummary>? cwShows,
    Map<String, List<ContentReference>>? iptvLists,
    bool? isLoading,
    bool? isHeroEmpty,
    String? error,
  }) {
    return HomeState(
      hero: hero ?? this.hero,
      cwMovies: cwMovies ?? this.cwMovies,
      cwShows: cwShows ?? this.cwShows,
      iptvLists: iptvLists ?? this.iptvLists,
      isLoading: isLoading ?? this.isLoading,
      isHeroEmpty: isHeroEmpty ?? this.isHeroEmpty,
      error: error ?? this.error,
    );
  }
}

/// Contrôleur Home avec enrichissement batché + annulation propre.
class HomeController extends Notifier<HomeState> {
  late final HomeFeedRepository _repo;
  late final LoadHomeHero _loadHero;
  late final LoadHomeContinueWatching _loadCw;
  late final LoadHomeIptvSections _loadIptv;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  HomeState build() {
    _repo = ref.watch(homeFeedRepositoryProvider);
    _loadHero = LoadHomeHero(_repo);
    _loadCw = LoadHomeContinueWatching(_repo);
    _loadIptv = LoadHomeIptvSections(_repo);
    if (_eventSub == null) {
      final bus = ref.watch(appEventBusProvider);
      _eventSub = bus.stream.listen((event) {
        if (event.type == AppEventType.iptvSynced) {
          unawaited(refresh());
        }
      });
      ref.onDispose(() {
        _eventSub?.cancel();
        _eventSub = null;
      });
    }
    return const HomeState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final hero = await _loadHero();
    final iptv = await _loadIptv();
    final movies = await _loadCw.movies();
    final shows = await _loadCw.shows();
    state = state.copyWith(
      hero: hero,
      cwMovies: movies,
      cwShows: shows,
      iptvLists: iptv,
      isLoading: false,
      isHeroEmpty: hero.isEmpty,
    );
  }

  Future<void> refresh() => load();
}

final homeFeedRepositoryProvider = Provider<HomeFeedRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<HomeFeedRepository>();
});

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);
