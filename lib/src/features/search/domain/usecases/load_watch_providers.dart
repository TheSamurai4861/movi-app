import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/domain/repositories/search_repository.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';

class LoadWatchProviders {
  const LoadWatchProviders(this._repo);

  final SearchRepository _repo;

  Future<List<WatchProvider>> call(String region) {
    return _repo.getWatchProviders(region);
  }

  Future<SearchPage<MovieSummary>> getMovies(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) {
    return _repo.getMoviesByProvider(providerId, region: region, page: page);
  }

  Future<SearchPage<TvShowSummary>> getShows(
    int providerId, {
    String region = 'FR',
    int page = 1,
  }) {
    return _repo.getShowsByProvider(providerId, region: region, page: page);
  }
}
