import '../entities/tv_show.dart';
import '../repositories/tv_repository.dart';

class GetTvWatchlist {
  const GetTvWatchlist(this._repository);

  final TvRepository _repository;

  Future<List<TvShowSummary>> call() => _repository.getUserWatchlist();
}
