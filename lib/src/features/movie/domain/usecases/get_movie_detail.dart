import '../entities/movie.dart';
import '../repositories/movie_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetMovieDetail {
  const GetMovieDetail(this._repository);

  final MovieRepository _repository;

  Future<Movie> call(MovieId id) => _repository.getMovie(id);
}
