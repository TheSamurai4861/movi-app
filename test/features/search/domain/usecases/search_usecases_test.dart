import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/usecases/search_movies.dart';
import 'package:movi/src/features/search/domain/usecases/search_shows.dart';
import 'package:movi/src/features/search/domain/usecases/search_people.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _SearchRepoStub implements SearchRepository {
  @override
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1}) async =>
      SearchPage(items: [MovieSummary(id: const MovieId('1'), tmdbId: 1, title: MediaTitle('A'), poster: Uri.parse('https://x'))], page: page, totalPages: 5);

  @override
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1}) async =>
      SearchPage(items: [TvShowSummary(id: const SeriesId('1'), tmdbId: 1, title: MediaTitle('S'), poster: Uri.parse('https://x'))], page: page, totalPages: 3);

  @override
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1}) async =>
      SearchPage(items: [PersonSummary(id: const PersonId('1'), tmdbId: 1, name: 'P')], page: page, totalPages: 2);
}

void main() {
  test('Search use cases delegate to repository and return SearchPage', () async {
    final repo = _SearchRepoStub();
    final movies = await SearchMovies(repo)('q', page: 2);
    final shows = await SearchShows(repo)('q');
    final people = await SearchPeople(repo)('q', page: 2);

    expect(movies.page, 2);
    expect(movies.items.first.title.value, 'A');
    expect(shows.items.first.title.value, 'S');
    expect(people.items.first.name, 'P');
  });
}

