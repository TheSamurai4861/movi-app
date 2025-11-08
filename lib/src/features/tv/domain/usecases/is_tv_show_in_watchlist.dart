import '../repositories/tv_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class IsTvShowInWatchlist {
  const IsTvShowInWatchlist(this._repository);

  final TvRepository _repository;

  Future<bool> call(SeriesId id) => _repository.isInWatchlist(id);
}
