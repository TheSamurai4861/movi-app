import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';

class GetContinueWatchingTv {
  const GetContinueWatchingTv(this._repository);

  final TvRepository _repository;

  Future<List<TvShowSummary>> call() => _repository.getContinueWatching();
}
