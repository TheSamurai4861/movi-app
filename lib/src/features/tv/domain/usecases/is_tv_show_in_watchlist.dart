import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class IsTvShowInWatchlist {
  const IsTvShowInWatchlist(this._repository);

  final TvRepository _repository;

  Future<bool> call(SeriesId id) => _repository.isInWatchlist(id);
}
