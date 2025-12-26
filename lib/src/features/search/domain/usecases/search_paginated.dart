import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

class SearchPaginated {
  const SearchPaginated(this._repo);

  final SearchRepository _repo;

  Future<SearchPage<MovieSummary>> movies(String query, {int page = 1}) =>
      _repo.searchMovies(query, page: page);

  Future<SearchPage<TvShowSummary>> shows(String query, {int page = 1}) =>
      _repo.searchShows(query, page: page);
}
