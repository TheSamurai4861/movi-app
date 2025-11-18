import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/search/domain/usecases/search_instant.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.movies = const <MovieSummary>[],
    this.shows = const <TvShowSummary>[],
    this.people = const <PersonSummary>[],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<MovieSummary> movies;
  final List<TvShowSummary> shows;
  final List<PersonSummary> people;
  final bool isLoading;
  final String? error;

  SearchState copyWith({
    String? query,
    List<MovieSummary>? movies,
    List<TvShowSummary>? shows,
    List<PersonSummary>? people,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      movies: movies ?? this.movies,
      shows: shows ?? this.shows,
      people: people ?? this.people,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchInstantController extends Notifier<SearchState> {
  late final SearchInstant _instant;

  Future<void> Function(String query)? _addToHistory;
  Timer? _debounce;

  @override
  SearchState build() {
    final locator = ref.watch(slProvider);
    final searchRepo = locator<SearchRepository>();
    _instant = SearchInstant(searchRepo);
    final historyRepo = ref.watch(searchHistoryRepositoryProvider);
    final addToHistory = AddSearchQueryToHistory(historyRepo);
    _addToHistory = (q) async {
      await addToHistory(q);
      await ref.read(searchHistoryControllerProvider.notifier).refresh();
    };
    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });
    return const SearchState();
  }

  void setQuery(String q) {
    final query = q.trim();
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.length < 3) {
      state = state.copyWith(
        movies: const [],
        shows: const [],
        people: const [],
        isLoading: false,
        error: null,
      );
      return;
    }
    _debounce = Timer(const Duration(seconds: 1), () => _performSearch(query));
  }

  void setQueryImmediate(String q) {
    final query = q.trim();
    _debounce?.cancel();
    state = state.copyWith(query: query);
    if (query.length < 3) {
      state = state.copyWith(
        movies: const [],
        shows: const [],
        people: const [],
        isLoading: false,
        error: null,
      );
      return;
    }
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await Future.wait([
        _instant.movies(query),
        _instant.shows(query),
        _instant.people(query),
      ]);
      final movies = res[0] as List<MovieSummary>;
      final shows = res[1] as List<TvShowSummary>;
      final people = res[2] as List<PersonSummary>;
      state = state.copyWith(
        movies: movies,
        shows: shows,
        people: people,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Échec de la recherche: $e',
      );
    } finally {
      final add = _addToHistory;
      if (add != null && query.trim().length >= 3) {
        await add(query);
      }
    }
  }
}
