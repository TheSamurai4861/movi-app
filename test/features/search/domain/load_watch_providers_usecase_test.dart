import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/usecases/load_watch_providers.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class FakeSearchRepository implements SearchRepository {
  List<WatchProvider>? watchProviders;
  Object? error;

  @override
  Future<List<WatchProvider>> getWatchProviders(String region) async {
    if (error != null) throw error!;
    return watchProviders ?? [];
  }

  @override
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1}) async =>
      const SearchPage(items: [], page: 1, totalPages: 1);

  @override
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1}) async =>
      const SearchPage(items: [], page: 1, totalPages: 1);

  @override
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1}) async =>
      const SearchPage(items: [], page: 1, totalPages: 1);

  @override
  Future<SearchPage<MovieSummary>> getMoviesByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) async => const SearchPage(items: [], page: 1, totalPages: 1);

  @override
  Future<SearchPage<TvShowSummary>> getShowsByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) async => const SearchPage(items: [], page: 1, totalPages: 1);
}

void main() {
  group('LoadWatchProviders', () {
    test('returns providers for a given region', () async {
      final repo = FakeSearchRepository();
      repo.watchProviders = [
        const WatchProvider(
          providerId: 1,
          providerName: 'Netflix',
          logoPath: '/logo.jpg',
          displayPriority: 1,
        ),
      ];
      final usecase = LoadWatchProviders(repo);

      final result = await usecase('FR');

      expect(result.length, 1);
      expect(result.first.providerName, 'Netflix');
    });

    test('rethrows repository errors', () async {
      final repo = FakeSearchRepository();
      repo.error = Exception('Network Error');
      final usecase = LoadWatchProviders(repo);

      expect(() => usecase('FR'), throwsException);
    });
  });
}

