import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetTvShowDetail {
  const GetTvShowDetail(this._repository);

  final TvRepository _repository;

  Future<TvShow> call(SeriesId id) => _repository.getShow(id);
}
