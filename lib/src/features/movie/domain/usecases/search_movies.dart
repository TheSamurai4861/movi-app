import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';

class SearchMovies {
  const SearchMovies(this._repository);

  final MovieRepository _repository;

  Future<List<MovieSummary>> call(String query) =>
      _repository.searchMovies(query.trim());
}
