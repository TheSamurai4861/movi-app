import '../entities/tv_show.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

abstract class TvRepository {
  Future<TvShow> getShow(SeriesId id);
  Future<List<Season>> getSeasons(SeriesId id);
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId);
  Future<List<TvShowSummary>> getFeaturedShows();
  Future<List<TvShowSummary>> getUserWatchlist();
  Future<List<TvShowSummary>> getContinueWatching();
  Future<List<TvShowSummary>> searchShows(String query);
  Future<bool> isInWatchlist(SeriesId id);
  Future<void> setWatchlist(SeriesId id, {required bool saved});
}
