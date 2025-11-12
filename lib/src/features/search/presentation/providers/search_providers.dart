// lib/src/features/search/presentation/providers/search_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';

import '../../../../core/di/injector.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_movies.dart';
import '../../domain/usecases/search_shows.dart';
import '../../domain/entities/search_page.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../models/search_results_args.dart';
import '../providers/search_history_providers.dart';

// --- Providers de dépendances ---
final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => sl<SearchRepository>(),
);

final searchMoviesUseCaseProvider = Provider<SearchMovies>(
  (ref) => SearchMovies(ref.read(searchRepositoryProvider)),
);
final searchShowsUseCaseProvider = Provider<SearchShows>(
  (ref) => SearchShows(ref.read(searchRepositoryProvider)),
);

// --- State & Controller: Recherche instantanée (top 10 + complet en mémoire) ---
class SearchState {
  const SearchState({
    this.query = '',
    this.movies = const <MovieSummary>[],
    this.shows = const <TvShowSummary>[],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<MovieSummary> movies;
  final List<TvShowSummary> shows;
  final bool isLoading;
  final String? error;

  SearchState copyWith({
    String? query,
    List<MovieSummary>? movies,
    List<TvShowSummary>? shows,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      movies: movies ?? this.movies,
      shows: shows ?? this.shows,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._movies, this._shows, [this._addToHistory])
    : super(const SearchState());

  final SearchMovies _movies;
  final SearchShows _shows;
  final Future<void> Function(String query)? _addToHistory;

  Timer? _debounce;

  void setQuery(String q) {
    final query = q.trim();
    state = state.copyWith(query: query);
    _debounce?.cancel();
    // Moins de 3 lettres → réinitialiser sans requête réseau
    if (query.length < 3) {
      state = state.copyWith(
        movies: const [],
        shows: const [],
        isLoading: false,
        error: null,
      );
      return;
    }
    _debounce = Timer(const Duration(seconds: 1), () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await Future.wait([_movies(query), _shows(query)]);
      final moviePage = res[0] as SearchPage<MovieSummary>;
      final showPage = res[1] as SearchPage<TvShowSummary>;
      state = state.copyWith(
        movies: moviePage.items,
        shows: showPage.items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec de la recherche: $e',
      );
    } finally {
      // Ajoute la requête à l'historique même en cas d'échec réseau,
      // pour respecter l'UX attendue (historique lié aux intentions utilisateur).
      final add = _addToHistory;
      if (add != null && query.trim().length >= 3) {
        unawaited(add(query));
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _debounce = null;
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
      final movies = ref.read(searchMoviesUseCaseProvider);
      final shows = ref.read(searchShowsUseCaseProvider);
      final repo = ref.read(searchHistoryRepositoryProvider);
      final addToHistory = AddSearchQueryToHistory(repo);
      return SearchController(movies, shows, (q) async {
        await addToHistory(q);
        // Rafraîchit la liste affichée pour refléter l’ajout immédiat
        await ref.read(searchHistoryControllerProvider.notifier).refresh();
      });
    });

// --- State & Controller: Résultats complets avec pagination ---
class SearchResultsState {
  const SearchResultsState({
    this.query = '',
    this.type = SearchResultsType.movies,
    this.itemsMovies = const <MovieSummary>[],
    this.itemsShows = const <TvShowSummary>[],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
  });

  final String query;
  final SearchResultsType type;
  final List<MovieSummary> itemsMovies;
  final List<TvShowSummary> itemsShows;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;

  bool get hasMore => page < totalPages;

  SearchResultsState copyWith({
    String? query,
    SearchResultsType? type,
    List<MovieSummary>? itemsMovies,
    List<TvShowSummary>? itemsShows,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
  }) {
    return SearchResultsState(
      query: query ?? this.query,
      type: type ?? this.type,
      itemsMovies: itemsMovies ?? this.itemsMovies,
      itemsShows: itemsShows ?? this.itemsShows,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchResultsController extends StateNotifier<SearchResultsState> {
  SearchResultsController(this._movies, this._shows, SearchResultsPageArgs args)
    : super(SearchResultsState(query: args.query, type: args.type));

  final SearchMovies _movies;
  final SearchShows _shows;

  Future<void> fetchFirstPage() async {
    state = state.copyWith(isLoading: true, error: null, page: 1);
    try {
      if (state.type == SearchResultsType.movies) {
        final page = await _movies(state.query, page: 1);
        state = state.copyWith(
          itemsMovies: page.items,
          totalPages: page.totalPages,
          isLoading: false,
        );
      } else {
        final page = await _shows(state.query, page: 1);
        state = state.copyWith(
          itemsShows: page.items,
          totalPages: page.totalPages,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement: $e',
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final next = state.page + 1;
    try {
      if (state.type == SearchResultsType.movies) {
        final page = await _movies(state.query, page: next);
        state = state.copyWith(
          itemsMovies: [...state.itemsMovies, ...page.items],
          page: next,
          totalPages: page.totalPages,
          isLoading: false,
        );
      } else {
        final page = await _shows(state.query, page: next);
        state = state.copyWith(
          itemsShows: [...state.itemsShows, ...page.items],
          page: next,
          totalPages: page.totalPages,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec du chargement: $e',
      );
    }
  }
}

final searchResultsControllerProvider =
    StateNotifierProvider.family<
      SearchResultsController,
      SearchResultsState,
      SearchResultsPageArgs
    >((ref, args) {
      final movies = ref.read(searchMoviesUseCaseProvider);
      final shows = ref.read(searchShowsUseCaseProvider);
      final ctrl = SearchResultsController(movies, shows, args);
      // Chargement initial
      unawaited(ctrl.fetchFirstPage());
      return ctrl;
    });
