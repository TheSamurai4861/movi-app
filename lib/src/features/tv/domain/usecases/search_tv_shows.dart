import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';

class SearchTvShows {
  const SearchTvShows(this._repository);

  final TvRepository _repository;

  Future<List<TvShowSummary>> call(String query) =>
      _repository.searchShows(query.trim());
}
