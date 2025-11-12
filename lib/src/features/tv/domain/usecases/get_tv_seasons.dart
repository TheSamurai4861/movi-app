import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetTvSeasons {
  const GetTvSeasons(this._repository);

  final TvRepository _repository;

  Future<List<Season>> call(SeriesId id) => _repository.getSeasons(id);
}
