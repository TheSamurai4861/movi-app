import '../../../movie/domain/entities/movie_summary.dart';
import '../../../tv/domain/entities/tv_show.dart';
import '../../../../shared/domain/entities/person_summary.dart';
import '../entities/search_page.dart';

abstract class SearchRepository {
  Future<SearchPage<MovieSummary>> searchMovies(String query, {int page = 1});
  Future<SearchPage<TvShowSummary>> searchShows(String query, {int page = 1});
  Future<SearchPage<PersonSummary>> searchPeople(String query, {int page = 1});
}
