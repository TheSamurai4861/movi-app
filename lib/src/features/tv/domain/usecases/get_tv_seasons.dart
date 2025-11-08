import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetTvSeasons {
  const GetTvSeasons(this._repository);

  final TvRepository _repository;

  Future<List<Season>> call(SeriesId id) => _repository.getSeasons(id);
}
