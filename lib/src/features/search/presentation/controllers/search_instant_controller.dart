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

void _debugSearchController(String message) {
  assert(() {
    debugPrint('[SearchCtrl][debug] $message');
    return true;
  }());
}

enum SearchUiMode {
  discovery,
  readyToSubmit,
  loadingResults,
  showingResults,
  error,
}

class SearchState {
  const SearchState({
    this.draftQuery = '',
    this.submittedQuery = '',
    this.movies = const <MovieSummary>[],
    this.shows = const <TvShowSummary>[],
    this.people = const <PersonSummary>[],
    this.sagas = const <SagaSummary>[],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
  });

  static const Object _sentinel = Object();

  final String draftQuery;
  final String submittedQuery;
  final List<MovieSummary> movies;
  final List<TvShowSummary> shows;
  final List<PersonSummary> people;
  final List<SagaSummary> sagas;
  final bool isLoading;
  final bool hasSearched;
  final String? error;

  String get query => submittedQuery;

  bool get canSubmitDraft => draftQuery.trim().length >= _minSearchQueryLength;

  bool get hasAnyResults =>
      movies.isNotEmpty ||
      shows.isNotEmpty ||
      people.isNotEmpty ||
      sagas.isNotEmpty;

  SearchUiMode get uiMode {
    final normalizedDraft = draftQuery.trim();
    final normalizedSubmitted = submittedQuery.trim();
    if (normalizedDraft.length < _minSearchQueryLength) {
      return SearchUiMode.discovery;
    }
    final hasCommittedDraft =
        hasSearched &&
        normalizedSubmitted.length >= _minSearchQueryLength &&
        normalizedDraft == normalizedSubmitted;
    if (!hasCommittedDraft) {
      return SearchUiMode.readyToSubmit;
    }
    if (isLoading) {
      return SearchUiMode.loadingResults;
    }
    if (error != null) {
      return SearchUiMode.error;
    }
    return SearchUiMode.showingResults;
  }

  SearchState copyWith({
    String? draftQuery,
    String? submittedQuery,
    List<MovieSummary>? movies,
    List<TvShowSummary>? shows,
    List<PersonSummary>? people,
    List<SagaSummary>? sagas,
    bool? isLoading,
    bool? hasSearched,
    Object? error = _sentinel,
  }) {
    return SearchState(
      draftQuery: draftQuery ?? this.draftQuery,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      movies: movies ?? this.movies,
      shows: shows ?? this.shows,
      people: people ?? this.people,
      sagas: sagas ?? this.sagas,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

class SearchInstantController extends Notifier<SearchState> {
  late final SearchInstant _instant;
  late final SearchSagas _searchSagas;

  Future<void> Function(String query)? _addToHistory;
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

        final q = state.submittedQuery.trim();
        if (q.length < _minSearchQueryLength) return;
        if (!state.hasSearched) return;
        final revision = ++_queryRevision;
        unawaited(
          _performSearch(q, requestRevision: revision, addToHistory: false),
        );
      });
    }
    return const SearchState();
  }

  void setDraftQuery(String q) {
    final query = q.trim();
    _debugSearchController('setDraftQuery query="$query" len=${query.length}');
    state = state.copyWith(
      draftQuery: query,
      error: query == state.submittedQuery ? state.error : null,
    );
    if (query.length < _minSearchQueryLength) {
      _debugSearchController(
        'setDraftQuery discovery mode (below min=$_minSearchQueryLength)',
      );
      state = state.copyWith(error: null);
    }
  }

  Future<void> submitCurrentQuery() async {
    await submitQuery(state.draftQuery);
  }

  Future<void> submitQuery(String q) async {
    final query = q.trim();
    final revision = ++_queryRevision;
    _debugSearchController(
      'submitQuery query="$query" len=${query.length} rev=$revision',
    );
    if (query.length < _minSearchQueryLength) {
      _debugSearchController(
        'submitQuery ignored (below min=$_minSearchQueryLength)',
      );
      return;
    }
    state = state.copyWith(
      draftQuery: query,
      submittedQuery: query,
      hasSearched: true,
      error: null,
    );
    await _performSearch(query, requestRevision: revision);
  }

  void clear() {
    final revision = ++_queryRevision;
    _debugSearchController('clear rev=$revision');
    state = const SearchState();
  }

  Future<void> _performSearch(
    String query, {
    required int requestRevision,
    bool addToHistory = true,
  }) async {
    if (requestRevision != _queryRevision || state.submittedQuery != query) {
      _debugSearchController(
        'skip stale search query="$query" requestRev=$requestRevision currentRev=$_queryRevision stateQuery="${state.submittedQuery}"',
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
      if (requestRevision != _queryRevision || state.submittedQuery != query) {
        _debugSearchController(
          'drop stale response query="$query" requestRev=$requestRevision currentRev=$_queryRevision stateQuery="${state.submittedQuery}"',
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
        hasSearched: true,
        error: null,
      );
      _debugSearchController(
        'search success query="$query" movies=${movies.length} shows=${shows.length} people=${people.length} sagas=${sagas.length}',
      );
    } catch (e) {
      if (requestRevision != _queryRevision || state.submittedQuery != query) {
        _debugSearchController(
          'drop stale error query="$query" requestRev=$requestRevision currentRev=$_queryRevision stateQuery="${state.submittedQuery}"',
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
          state.submittedQuery == query &&
          addToHistory &&
          add != null &&
          query.trim().length >= _minSearchQueryLength) {
        await add(query);
        _debugSearchController('history add query="$query"');
      }
    }
  }
}
