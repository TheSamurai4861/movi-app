import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';

class SearchMovies {
  const SearchMovies(this._repository);

  final SearchRepository _repository;

  Future<SearchPage<MovieSummary>> call(String query, {int page = 1}) {
    return _repository.searchMovies(query, page: page);
  }
}
