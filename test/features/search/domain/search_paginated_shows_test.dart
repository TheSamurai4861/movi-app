import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/usecases/search_paginated.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';

class _FakeSearchRepo implements SearchRepository {
  int? lastPageShows;
  String? lastQueryShows;

  @override
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1}) async {
    lastQueryShows = query;
    lastPageShows = page;
    return SearchPage(items: const <TvShowSummary>[], page: page, totalPages: 5);
  }

  @override
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1}) async {
    return SearchPage(items: const <MovieSummary>[], page: page, totalPages: 1);
  }

  @override
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1}) async {
    return SearchPage(items: const <PersonSummary>[], page: page, totalPages: 1);
  }

  @override
  Future<List<WatchProvider>> getWatchProviders(String region) async => const <WatchProvider>[];
  @override
  Future<SearchPage<MovieSummary>> getMoviesByProvider(int providerId, {String region = 'FR', int page = 1}) async {
    return SearchPage(items: const <MovieSummary>[], page: page, totalPages: 1);
  }
  @override
  Future<SearchPage<TvShowSummary>> getShowsByProvider(int providerId, {String region = 'FR', int page = 1}) async {
    return SearchPage(items: const <TvShowSummary>[], page: page, totalPages: 1);
  }
}

void main() {
  test('SearchPaginated.shows transmet bien la page et le query', () async {
    final repo = _FakeSearchRepo();
    final usecase = SearchPaginated(repo);

    final res = await usecase.shows('query test', page: 3);
    expect(repo.lastQueryShows, 'query test');
    expect(repo.lastPageShows, 3);
    expect(res.page, 3);
    expect(res.totalPages, 5);
  });
}