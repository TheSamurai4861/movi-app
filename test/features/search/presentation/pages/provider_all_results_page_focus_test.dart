import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/usecases/load_watch_providers.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/features/search/presentation/pages/provider_all_results_page.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

void main() {
  testWidgets(
    'backspace pops provider all results and initial focus lands on first item',
    (tester) async {
      final repo = _FakeSearchRepository();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/provider'),
                  child: const Text('Open provider'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/provider',
            builder: (context, state) => ProviderAllResultsPage(
              args: const ProviderAllResultsArgs(
                providerId: 8,
                providerName: 'Netflix',
                type: MoviMediaType.movie,
              ),
              type: MoviMediaType.movie,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      final getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);

      final container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(getIt),
          currentProfileProvider.overrideWithValue(null),
          loadWatchProvidersUseCaseProvider.overrideWithValue(
            LoadWatchProviders(repo),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open provider'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'ProviderAllFirstItem',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      expect(find.text('Open provider'), findsOneWidget);
    },
  );
}

class _FakeSearchRepository implements SearchRepository {
  @override
  Future<SearchPage<MovieSummary>> getMoviesByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) async {
    return SearchPage<MovieSummary>(
      items: [
        MovieSummary(
          id: const MovieId('movie-1'),
          title: MediaTitle('Movie 1'),
          poster: Uri.parse('https://example.com/poster.jpg'),
          releaseYear: 2024,
        ),
      ],
      page: 1,
      totalPages: 1,
    );
  }

  @override
  Future<SearchPage<TvShowSummary>> getShowsByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) async {
    return SearchPage<TvShowSummary>(items: const [], page: 1, totalPages: 1);
  }

  @override
  Future<List<WatchProvider>> getWatchProviders(String region) async {
    return const [];
  }

  @override
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1}) {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1}) {
    throw UnimplementedError();
  }

  @override
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1}) {
    throw UnimplementedError();
  }
}
