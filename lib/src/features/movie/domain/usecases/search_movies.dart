import '../entities/movie_summary.dart';
import '../repositories/movie_repository.dart';

class SearchMovies {
  const SearchMovies(this._repository);

  final MovieRepository _repository;

  Future<List<MovieSummary>> call(String query) =>
      _repository.searchMovies(query.trim());
}
