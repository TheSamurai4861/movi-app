import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetMovieDetail {
  const GetMovieDetail(this._repository);

  final MovieRepository _repository;

  Future<Movie> call(MovieId id) => _repository.getMovie(id);
}
