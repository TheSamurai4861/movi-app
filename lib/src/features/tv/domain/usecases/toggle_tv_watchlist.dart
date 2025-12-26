import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class ToggleTvWatchlist {
  const ToggleTvWatchlist(this._repository);

  final TvRepository _repository;

  Future<void> call(SeriesId id, {required bool saved}) {
    return _repository.setWatchlist(id, saved: saved);
  }
}
