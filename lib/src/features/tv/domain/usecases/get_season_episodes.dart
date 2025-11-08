import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class GetSeasonEpisodes {
  const GetSeasonEpisodes(this._repository);

  final TvRepository _repository;

  Future<List<Episode>> call(SeriesId showId, SeasonId seasonId) {
    return _repository.getEpisodes(showId, seasonId);
  }
}
