import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/search/domain/usecases/search_instant.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';
import 'package:movi/src/features/saga/domain/usecases/search_sagas.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

const int _minSearchQueryLength = 3;
const Duration _searchInputDebounce = Duration(milliseconds: 1400);

void _debugSearchController(String message) {
  assert(() {
    debugPrint('[SearchCtrl][debug] $message');
    return true;
  }());
}

class SearchState {
  const SearchState({
    this.query = '',
    this.movies = const <MovieSummary>[],
    this.shows = const <TvShowSummary>[],
    this.people = const <PersonSummary>[],
    this.sagas = const <SagaSummary>[],
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<MovieSummary> movies;
  final List<TvShowSummary> shows;
  final List<PersonSummary> people;
  final List<SagaSummary> sagas;
  final bool isLoading;
  final String? error;

  SearchState copyWith({
    String? query,
    List<MovieSummary>? movies,
    List<TvShowSummary>? shows,
    List<PersonSummary>? people,
    List<SagaSummary>? sagas,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      movies: movies ?? this.movies,
      shows: shows ?? this.shows,
      people: people ?? this.people,
      sagas: sagas ?? this.sagas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchInstantController extends Notifier<SearchState> {
  late final SearchInstant _instant;
  late final SearchSagas _searchSagas;

  Future<void> Function(String query)? _addToHistory;
  Timer? _debounce;
  bool _profileListenerAttached = false;
  int _queryRevision = 0;

  @override
  SearchState build() {
    final locator = ref.watch(slProvider);
    final searchRepo = locator<SearchRepository>();
    _instant = SearchInstant(searchRepo);
    final sagaRepo = locator<SagaRepository>();
    _searchSagas = SearchSagas(sagaRepo);
    final historyRepo = ref.watch(searchHistoryRepositoryProvider);
    final addToHistory = AddSearchQueryToHistory(historyRepo);
    _addToHistory = (q) async {
      await addToHistory(q);
      await ref.read(searchHistoryControllerProvider.notifier).refresh();
    };

    if (!_profileListenerAttached) {
      _profileListenerAttached = true;
      // When the profile restriction changes (kid/PEGI), re-run the current search
      // so the UI updates immediately.
      ref.listen(currentProfileProvider, (previous, next) {
        final changed =
            previous?.id != next?.id ||
            previous?.isKid != next?.isKid ||
            previous?.pegiLimit != next?.pegiLimit;
        if (!changed) return;

        final q = state.query.trim();
        if (q.length < _minSearchQueryLength) return;
        _debounce?.cancel();
        _debounce = null;
        final revision = _queryRevision;
        unawaited(
          _performSearch(q, requestRevision: revision, addToHistory: false),
        );
      });
    }

    ref.onDispose(() {
      _debounce?.cancel();
      _debounce = null;
    });
    return const SearchState();
  }

  void setQuery(String q) {
    final query = q.trim();
    final revision = ++_queryRevision;
    _debugSearchController(
      'setQuery query="$query" len=${query.length} rev=$revision',
    );
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.length < _minSearchQueryLength) {
      _debugSearchController(
        'setQuery cleared results (below min=$_minSearchQueryLength)',
      );
      state = state.copyWith(
        movies: const [],
        shows: const [],
        people: const [],
        sagas: const [],
        isLoading: false,
        error: null,
      );
      return;
    }
    _debounce = Timer(_searchInputDebounce, () {
      _debugSearchController('debounce fired query="$query" rev=$revision');
      _performSearch(query, requestRevision: revision, addToHistory: false);
    });
  }

  void setQueryImmediate(String q) {
    final query = q.trim();
    final revision = ++_queryRevision;
    _debugSearchController(
      'setQueryImmediate query="$query" len=${query.length} rev=$revision',
    );
    _debounce?.cancel();
    state = state.copyWith(query: query);
    if (query.length < _minSearchQueryLength) {
      state = state.copyWith(
        movies: const [],
        shows: const [],
        people: const [],
        sagas: const [],
        isLoading: false,
        error: null,
      );
      return;
    }
    _performSearch(query, requestRevision: revision);
  }

  Future<void> _performSearch(
    String query, {
    required int requestRevision,
    bool addToHistory = true,
  }) async {
    if (requestRevision != _queryRevision || state.query != query) {
      _debugSearchController(
        'skip stale search query="$query" requestRev=$requestRevision currentRev=$_queryRevision stateQuery="${state.query}"',
      );
      return;
    }
    _debugSearchController(
      'start search query="$query" rev=$requestRevision addToHistory=$addToHistory',
    );
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await Future.wait([
        _instant.movies(query),
        _instant.shows(query),
        _instant.people(query),
        _searchSagas(query),
      ]);
      if (requestRevision != _queryRevision || state.query != query) {
        _debugSearchController(
          'drop stale response query="$query" requestRev=$requestRevision currentRev=$_queryRevision stateQuery="${state.query}"',
        );
        return;
      }
      var movies = res[0] as List<MovieSummary>;
      var shows = res[1] as List<TvShowSummary>;
      final people = res[2] as List<PersonSummary>;
      final sagas = res[3] as List<SagaSummary>;

      final profile = ref.read(currentProfileProvider);
      final bool hasRestrictions =
          profile != null && (profile.isKid || profile.pegiLimit != null);
      if (hasRestrictions) {
        final policy = ref.read(parental.agePolicyProvider);

        final movieRefs = movies
            .map(
              (m) => ContentReference(
                id: m.id.value,
                type: ContentType.movie,
                title: m.title,
              ),
            )
            .toList(growable: false);
        final showRefs = shows
            .map(
              (s) => ContentReference(
                id: s.id.value,
                type: ContentType.series,
                title: s.title,
              ),
            )
            .toList(growable: false);

        try {
          final allowedMovies = await policy.filterAllowed(movieRefs, profile);
          final allowedMovieIds = allowedMovies.map((r) => r.id).toSet();
          movies = movies
              .where((m) => allowedMovieIds.contains(m.id.value))
              .toList();
        } catch (_) {}

        try {
          final allowedShows = await policy.filterAllowed(showRefs, profile);
          final allowedShowIds = allowedShows.map((r) => r.id).toSet();
          shows = shows
              .where((s) => allowedShowIds.contains(s.id.value))
              .toList();
        } catch (_) {}
      }

      state = state.copyWith(
        movies: movies,
        shows: shows,
        people: people,
        sagas: sagas,
        isLoading: false,
      );
      _debugSearchController(
        'search success query="$query" movies=${movies.length} shows=${shows.length} people=${people.length} sagas=${sagas.length}',
      );
    } catch (e) {
      if (requestRevision != _queryRevision || state.query != query) {
        _debugSearchController(
          'drop stale error query="$query" requestRev=$requestRevision currentRev=$_queryRevision stateQuery="${state.query}"',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Échec de la recherche: $e',
      );
      _debugSearchController('search error query="$query" error=$e');
    } finally {
      final add = _addToHistory;
      if (requestRevision == _queryRevision &&
          state.query == query &&
          addToHistory &&
          add != null &&
          query.trim().length >= _minSearchQueryLength) {
        await add(query);
        _debugSearchController('history add query="$query"');
      }
    }
  }
}
