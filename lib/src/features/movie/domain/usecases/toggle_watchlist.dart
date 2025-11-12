import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class ToggleWatchlist {
  const ToggleWatchlist(this._repository);

  final MovieRepository _repository;

  Future<void> call(MovieId id, {required bool saved}) {
    return _repository.setWatchlist(id, saved: saved);
  }
}
