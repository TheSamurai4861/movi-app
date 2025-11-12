// lib/src/features/home/presentation/providers/home_providers.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/logging/logging_service.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';
import '../../domain/repositories/home_feed_repository.dart';

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
class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repo) : super(const HomeState());

  final HomeFeedRepository _repo;

  /// Concurrence maximale d’enrichissements en parallèle.
  static const int _maxConcurrent = 6;

  /// Requêtes en cours par carte (clé "section#index") → CancelToken.
  final Map<String, CancelToken> _inflight = <String, CancelToken>{};

  /// Buffer de patches UI: section → (index → ref enrichie).
  final Map<String, Map<int, ContentReference>> _pendingPatches = {};

  /// Timer de coalescence UI.
  Timer? _flushTimer;

  /// Démarrage: charge le hero synchronement, le reste en asynchrone.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    unawaited(LoggingService.log('Home: load start'));

    try {
      final hero = await _repo.getHeroMovies();
      final bool empty = hero.isEmpty;
      state = state.copyWith(hero: hero, isLoading: false, isHeroEmpty: empty);
      if (empty) {
        unawaited(LoggingService.log('Home: hero empty'));
      }
      unawaited(LoggingService.log('Home: hero loaded count=${hero.length}'));
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement du hero : $e',
      );
      unawaited(LoggingService.log('Home: hero load error=$e'));
    }

    // Laisser respirer un frame pour afficher le Hero avant de lancer les listes.
    await Future.delayed(const Duration(milliseconds: 48));

    unawaited(_loadIptvLists());
    unawaited(_loadCwMovies());
    unawaited(_loadCwShows());
    unawaited(LoggingService.log('Home: async sections loading started'));
  }

  Future<void> refresh() => load();

  Future<void> _loadIptvLists() async {
    try {
      final lists = await _repo.getIptvCategoryLists();
      state = state.copyWith(iptvLists: lists);
      unawaited(
        LoggingService.log('Home: iptv lists loaded sections=${lists.length}'),
      );
    } catch (e) {
      unawaited(LoggingService.log('Home: iptv lists load error=$e'));
    }
  }

  Future<void> _loadCwMovies() async {
    try {
      final cw = await _repo.getContinueWatchingMovies();
      state = state.copyWith(cwMovies: cw);
      unawaited(
        LoggingService.log('Home: cw movies loaded count=${cw.length}'),
      );
    } catch (_) {}
  }

  Future<void> _loadCwShows() async {
    try {
      final cw = await _repo.getContinueWatchingShows();
      state = state.copyWith(cwShows: cw);
      unawaited(LoggingService.log('Home: cw shows loaded count=${cw.length}'));
    } catch (_) {}
  }

  /// Enrichit une fenêtre visible [start..start+count-1] pour la section [key].
  /// - Lance au plus [_maxConcurrent] jobs simultanés.
  /// - Déduplique par carte (section#index).
  /// - Bufferise les mises à jour UI (flush toutes ~24ms).
  Future<void> enrichCategoryBatch(String key, int start, int count) async {
    final list = state.iptvLists[key];
    if (list == null || list.isEmpty || count <= 0) return;
    unawaited(
      LoggingService.log(
        'Home: enrich start key=$key start=$start count=$count',
      ),
    );

    final clampedStart = start.clamp(0, list.length - 1);
    final end = (clampedStart + count - 1).clamp(0, list.length - 1);

    final tasks = <Future<void>>[];
    for (var i = clampedStart; i <= end; i++) {
      final ref = list[i];
      final cardKey = '$key#$i';

      if (_inflight.containsKey(cardKey)) continue;

      // Accepter les posters IPTV http(s) s’ils sont compatibles avec la plateforme.
      // Sur le Web, les images http peuvent être bloquées (mixed content) → enrichissement pour obtenir un poster TMDB https.
      final bool isHttpPosterOnWeb =
          kIsWeb && ref.poster != null && ref.poster!.scheme == 'http';
      final needsEnrich =
          ref.year == null ||
          ref.rating == null ||
          ref.poster == null ||
          isHttpPosterOnWeb;

      if (!needsEnrich) continue;

      final token = CancelToken();
      _inflight[cardKey] = token;

      tasks.add(_enrichOne(key, i, ref, cardKey, token));

      if (tasks.length >= _maxConcurrent) {
        await Future.wait(tasks);
        tasks.clear();
      }
    }

    if (tasks.isNotEmpty) {
      await Future.wait(tasks);
    }
  }

  /// Annule toutes les requêtes en cours **hors** de la fenêtre [start..start+count-1].
  /// À appeler lors d’un gros scroll pour relâcher la pression réseau.
  void cancelOffscreen(String key, int start, int count) {
    final list = state.iptvLists[key];
    if (list == null || list.isEmpty || count <= 0) return;

    final clampedStart = start.clamp(0, list.length - 1);
    final end = (clampedStart + count - 1).clamp(0, list.length - 1);

    final keysToCancel = <String>[];
    _inflight.forEach((k, token) {
      final parts = k.split('#');
      if (parts.length != 2 || parts.first != key) return;
      final idx = int.tryParse(parts.last);
      if (idx == null) return;
      if (idx < clampedStart || idx > end) {
        keysToCancel.add(k);
      }
    });

    for (final k in keysToCancel) {
      _inflight[k]?.cancel('Offscreen');
      _inflight.remove(k);
    }
    if (keysToCancel.isNotEmpty) {
      unawaited(
        LoggingService.log(
          'Home: canceled offscreen requests key=$key count=${keysToCancel.length}',
        ),
      );
    }
  }

  Future<void> _enrichOne(
    String key,
    int index,
    ContentReference ref,
    String inflightKey,
    CancelToken token,
  ) async {
    try {
      // IMPORTANT: nécessite que HomeFeedRepository.enrichReference supporte CancelToken?.
      final enriched = await _repo.enrichReference(ref, cancelToken: token);

      // Si annulé entre-temps, on évite de bufferiser.
      if (token.isCancelled) return;

      _bufferPatch(key, index, enriched);
    } catch (_) {
      // Silencieux en prod, logs côté repo/executor.
    } finally {
      _inflight.remove(inflightKey);
    }
  }

  void _bufferPatch(String key, int index, ContentReference enriched) {
    final byIndex = _pendingPatches.putIfAbsent(
      key,
      () => <int, ContentReference>{},
    );
    byIndex[index] = enriched;

    // Augmente légèrement l’intervalle pour réduire la pression sur le thread UI Windows.
    final ms = defaultTargetPlatform == TargetPlatform.windows ? 64 : 48;
    _flushTimer ??= Timer(Duration(milliseconds: ms), _flushPatches);
  }

  void _flushPatches() {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_pendingPatches.isEmpty) return;

    final current = Map<String, List<ContentReference>>.from(state.iptvLists);

    _pendingPatches.forEach((section, patches) {
      final list = current[section];
      if (list == null || list.isEmpty) return;

      final copy = List<ContentReference>.from(list);
      patches.forEach((idx, ref) {
        if (idx >= 0 && idx < copy.length) {
          copy[idx] = ref;
        }
      });
      current[section] = copy;
    });

    _pendingPatches.clear();
    state = state.copyWith(iptvLists: current);
  }

  @override
  void dispose() {
    // Annule le timer de coalescence UI
    _flushTimer?.cancel();
    _flushTimer = null;

    // Annule toutes les requêtes réseau encore en vol
    for (final token in _inflight.values) {
      token.cancel('Dispose');
    }
    _inflight.clear();

    // Vide les patches en attente pour éviter des setState post-destruction
    _pendingPatches.clear();

    super.dispose();
  }
}

final homeFeedRepositoryProvider = Provider<HomeFeedRepository>(
  (ref) => sl<HomeFeedRepository>(),
);

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.read(homeFeedRepositoryProvider))..load(),
);
