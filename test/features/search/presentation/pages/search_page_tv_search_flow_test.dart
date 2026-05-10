import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
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
import 'package:movi/src/features/search/presentation/pages/search_page.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  group('SearchPage TV-first search flow', () {
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
          canAccessPremiumFeatureProvider.overrideWith(
            (ref, feature) async => false,
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await getIt.reset();
    });

    testWidgets('typing below the minimum keeps focus and does not search', (
      tester,
    ) async {
      await _pumpSearchPage(tester, container);
      final textFieldFinder = find.byType(TextField);

      await tester.tap(textFieldFinder);
      await tester.pump();
      await tester.enterText(textFieldFinder, 'ab');
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);
      expect(searchRepository.movieQueries, isEmpty);
      expect(
        container.read(searchControllerProvider).uiMode,
        SearchUiMode.discovery,
      );
    });

    testWidgets(
      'reaching the minimum length keeps focus and waits for explicit submit',
      (tester) async {
        await _pumpSearchPage(tester, container);
        final textFieldFinder = find.byType(TextField);

        await tester.tap(textFieldFinder);
        await tester.pump();
        await tester.enterText(textFieldFinder, 'ab');
        await tester.pump();
        await tester.enterText(textFieldFinder, 'abc');
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode?.hasFocus, isTrue);
        expect(searchRepository.movieQueries, isEmpty);
        expect(
          container.read(searchControllerProvider).uiMode,
          SearchUiMode.readyToSubmit,
        );
        expect(find.text('Search'), findsWidgets);
      },
    );

    testWidgets('submitting the query launches search and keeps focus', (
      tester,
    ) async {
      final pending = searchRepository.preparePendingMovieSearch('abc');
      await _pumpSearchPage(tester, container);
      final textFieldFinder = find.byType(TextField);

      await tester.tap(textFieldFinder);
      await tester.pump();
      await tester.enterText(textFieldFinder, 'abc');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(searchRepository.movieQueries, ['abc']);
      expect(container.read(searchControllerProvider).isLoading, isTrue);
      expect(
        tester.widget<TextField>(textFieldFinder).focusNode?.hasFocus,
        isTrue,
      );

      pending.complete(_movieResults('Result abc'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        container.read(searchControllerProvider).uiMode,
        SearchUiMode.showingResults,
      );
      expect(
        tester.widget<TextField>(textFieldFinder).focusNode?.hasFocus,
        isTrue,
      );
      expect(find.text('Result abc'), findsOneWidget);

      await _disposeApp(tester);
    });

    testWidgets('selecting a history item submits explicitly and syncs input', (
      tester,
    ) async {
      historyRepository.seed('matrix');
      searchRepository.preparePendingMovieSearch('matrix');
      await _pumpSearchPage(tester, container);
      final textFieldFinder = find.byType(TextField);

      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('matrix'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(searchRepository.movieQueries, ['matrix']);
      expect(
        tester.widget<TextField>(textFieldFinder).controller?.text,
        'matrix',
      );
      expect(
        tester.widget<TextField>(textFieldFinder).focusNode?.hasFocus,
        isTrue,
      );
      expect(
        container.read(searchControllerProvider).uiMode,
        SearchUiMode.loadingResults,
      );

      await _disposeApp(tester);
    });
  });
}

Future<void> _pumpSearchPage(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SearchPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

class _FakeSearchRepository implements SearchRepository {
  final List<String> movieQueries = <String>[];
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
    return const <SagaSummary>[];
  }
}

class _FakeSearchHistoryRepository implements SearchHistoryRepository {
  final List<SearchHistoryItem> _items = <SearchHistoryItem>[];

  void seed(String query) {
    _items.add(SearchHistoryItem(query: query, savedAt: DateTime(2026, 1, 1)));
  }

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
