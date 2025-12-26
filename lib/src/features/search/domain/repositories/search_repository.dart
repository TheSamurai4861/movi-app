import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/features/search/domain/entities/search_page.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';

abstract class SearchRepository {
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1});
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1});
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1});
  Future<List<WatchProvider>> getWatchProviders(String region);
  
  Future<SearchPage<MovieSummary>> getMoviesByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  });

  Future<SearchPage<TvShowSummary>> getShowsByProvider(
    int providerId, {
    String region = 'FR',
    int page = 1,
  });
}
