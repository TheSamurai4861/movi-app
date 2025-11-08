import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';

class GetFeaturedTvShows {
  const GetFeaturedTvShows(this._repository);

  final TvRepository _repository;

  Future<List<TvShowSummary>> call() => _repository.getFeaturedShows();
}
