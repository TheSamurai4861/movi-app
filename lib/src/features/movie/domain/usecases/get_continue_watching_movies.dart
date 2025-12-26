import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';

class GetContinueWatchingMovies {
  const GetContinueWatchingMovies(this._repository);

  final MovieRepository _repository;

  Future<List<MovieSummary>> call() => _repository.getContinueWatching();
}
