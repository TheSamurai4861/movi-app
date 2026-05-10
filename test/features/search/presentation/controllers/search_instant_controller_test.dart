import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart'
    as domain;
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/presentation/controllers/search_instant_controller.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  group('SearchInstantController', () {
    late GetIt getIt;
    late _FakeSearchRepository searchRepository;
    late _FakeSagaRepository sagaRepository;
    late _FakeSearchHistoryRepository historyRepository;
    late ProviderContainer container;

    setUp(() {
      getIt = GetIt.asNewInstance();
      searchRepository = _FakeSearchRepository();
      sagaRepository = _FakeSagaRepository();
      historyRepository = _FakeSearchHistoryRepository();

      getIt.registerSingleton<SearchRepository>(searchRepository);
      getIt.registerSingleton<SagaRepository>(sagaRepository);
      getIt.registerSingleton<SearchHistoryRepository>(historyRepository);

      container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(getIt),
          currentProfileProvider.overrideWithValue(null),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await getIt.reset();
    });

    test('setDraftQuery does not trigger a search', () {
      final notifier = container.read(searchControllerProvider.notifier);

      notifier.setDraftQuery('abc');

      final state = container.read(searchControllerProvider);
      expect(state.draftQuery, 'abc');
      expect(state.submittedQuery, isEmpty);
      expect(state.uiMode, SearchUiMode.readyToSubmit);
      expect(searchRepository.movieQueries, isEmpty);
      expect(searchRepository.showQueries, isEmpty);
      expect(searchRepository.peopleQueries, isEmpty);
      expect(sagaRepository.queries, isEmpty);
    });

    test(
      'submitCurrentQuery ignores queries shorter than the minimum',
      () async {
        final notifier = container.read(searchControllerProvider.notifier);
        notifier.setDraftQuery('ab');

        await notifier.submitCurrentQuery();

        final state = container.read(searchControllerProvider);
        expect(state.draftQuery, 'ab');
        expect(state.submittedQuery, isEmpty);
        expect(state.hasSearched, isFalse);
        expect(state.uiMode, SearchUiMode.discovery);
        expect(searchRepository.movieQueries, isEmpty);
      },
    );

    test(
      'submitCurrentQuery launches a full search for a valid query',
      () async {
        final notifier = container.read(searchControllerProvider.notifier);
        notifier.setDraftQuery('matrix');

        await notifier.submitCurrentQuery();

        final state = container.read(searchControllerProvider);
        expect(state.draftQuery, 'matrix');
        expect(state.submittedQuery, 'matrix');
        expect(state.hasSearched, isTrue);
        expect(state.uiMode, SearchUiMode.showingResults);
        expect(state.movies, hasLength(1));
        expect(searchRepository.movieQueries, ['matrix']);
        expect(searchRepository.showQueries, ['matrix']);
        expect(searchRepository.peopleQueries, ['matrix']);
        expect(sagaRepository.queries, ['matrix']);
      },
    );

    test('stale responses do not overwrite a newer submitted query', () async {
      final notifier = container.read(searchControllerProvider.notifier);
      final firstSearch = searchRepository.preparePendingMovieSearch('matrix');
      final secondSearch = searchRepository.preparePendingMovieSearch(
        'matrix reloaded',
      );

      notifier.setDraftQuery('matrix');
      final firstSubmit = notifier.submitCurrentQuery();
      await Future<void>.delayed(Duration.zero);

      notifier.setDraftQuery('matrix reloaded');
      final secondSubmit = notifier.submitCurrentQuery();
      await Future<void>.delayed(Duration.zero);

      firstSearch.complete(_movieResults('Old result'));
      await Future<void>.delayed(Duration.zero);

      var state = container.read(searchControllerProvider);
      expect(state.submittedQuery, 'matrix reloaded');
      expect(state.isLoading, isTrue);
      expect(state.movies, isEmpty);

      secondSearch.complete(_movieResults('New result'));
      await Future.wait([firstSubmit, secondSubmit]);

      state = container.read(searchControllerProvider);
      expect(state.submittedQuery, 'matrix reloaded');
      expect(state.isLoading, isFalse);
      expect(state.movies.single.title.display, 'New result');
    });

    test('clear resets the controller to discovery mode', () async {
      final notifier = container.read(searchControllerProvider.notifier);
      notifier.setDraftQuery('matrix');
      await notifier.submitCurrentQuery();

      notifier.clear();

      final state = container.read(searchControllerProvider);
      expect(state, const SearchState());
      expect(state.uiMode, SearchUiMode.discovery);
    });
  });
}

class _FakeSearchRepository implements SearchRepository {
  final List<String> movieQueries = <String>[];
  final List<String> showQueries = <String>[];
  final List<String> peopleQueries = <String>[];
  final Map<String, Completer<domain.SearchPage<MovieSummary>>> _pendingMovies =
      <String, Completer<domain.SearchPage<MovieSummary>>>{};

  Completer<domain.SearchPage<MovieSummary>> preparePendingMovieSearch(
    String query,
  ) {
    final completer = Completer<domain.SearchPage<MovieSummary>>();
    _pendingMovies[query] = completer;
    return completer;
  }

  @override
  Future<domain.SearchPage<MovieSummary>> searchMovies(
    String query, {
    int page = 1,
  }) {
    movieQueries.add(query);
    final pending = _pendingMovies.remove(query);
    if (pending != null) {
      return pending.future;
    }
    return Future<domain.SearchPage<MovieSummary>>.value(
      _movieResults('Movie $query'),
    );
  }

  @override
  Future<domain.SearchPage<TvShowSummary>> searchShows(
    String query, {
    int page = 1,
  }) async {
    showQueries.add(query);
    return const domain.SearchPage<TvShowSummary>(
      items: <TvShowSummary>[],
      page: 1,
      totalPages: 1,
    );
  }

  @override
  Future<domain.SearchPage<PersonSummary>> searchPeople(
    String query, {
    int page = 1,
  }) async {
    peopleQueries.add(query);
    return const domain.SearchPage<PersonSummary>(
      items: <PersonSummary>[],
      page: 1,
      totalPages: 1,
    );
  }

  @override
  Future<List<WatchProvider>> getWatchProviders(String region) async {
    return const <WatchProvider>[];
  }

  @override
  Future<domain.SearchPage<MovieSummary>> getMoviesByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<domain.SearchPage<TvShowSummary>> getShowsByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSagaRepository implements SagaRepository {
  final List<String> queries = <String>[];

  @override
  Future<Saga> getSaga(SagaId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<SagaSummary>> getUserSagas(String userId) async {
    return const <SagaSummary>[];
  }

  @override
  Future<List<SagaSummary>> searchSagas(String query) async {
    queries.add(query);
    return const <SagaSummary>[];
  }
}

class _FakeSearchHistoryRepository implements SearchHistoryRepository {
  final List<SearchHistoryItem> _items = <SearchHistoryItem>[];

  @override
  Future<void> add(String query) async {
    _items.removeWhere((item) => item.query == query);
    _items.add(
      SearchHistoryItem(
        query: query,
        savedAt: DateTime(2026, 1, _items.length + 1),
      ),
    );
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<List<SearchHistoryItem>> list() async {
    return List<SearchHistoryItem>.unmodifiable(_items);
  }

  @override
  Future<void> remove(String query) async {
    _items.removeWhere((item) => item.query == query);
  }
}

domain.SearchPage<MovieSummary> _movieResults(String title) {
  return domain.SearchPage<MovieSummary>(
    items: [
      MovieSummary(
        id: MovieId(title.toLowerCase().replaceAll(' ', '-')),
        title: MediaTitle(title),
        poster: Uri.parse('https://example.com/poster.jpg'),
      ),
    ],
    page: 1,
    totalPages: 1,
  );
}
