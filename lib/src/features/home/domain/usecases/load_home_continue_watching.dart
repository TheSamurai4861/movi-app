import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';

class LoadHomeContinueWatching {
  const LoadHomeContinueWatching(this._repo);

  final HomeFeedRepository _repo;

  Future<List<MovieSummary>> movies() => _repo.getContinueWatchingMovies();
  Future<List<TvShowSummary>> shows() => _repo.getContinueWatchingShows();
}
