import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

class SearchInstant {
  const SearchInstant(this._repo);

  final SearchRepository _repo;

  Future<List<MovieSummary>> movies(String query) async {
    final page = await _repo.searchMovies(query, page: 1);
    return page.items;
  }

  Future<List<TvShowSummary>> shows(String query) async {
    final page = await _repo.searchShows(query, page: 1);
    return page.items;
  }
}
