import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetTvShowDetail {
  const GetTvShowDetail(this._repository);

  final TvRepository _repository;

  Future<TvShow> call(SeriesId id) => _repository.getShow(id);
}
