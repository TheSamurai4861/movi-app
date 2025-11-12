import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class IsMovieInWatchlist {
  const IsMovieInWatchlist(this._repository);

  final MovieRepository _repository;

  Future<bool> call(MovieId id) => _repository.isInWatchlist(id);
}
