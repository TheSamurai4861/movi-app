import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

abstract class TvRepository {
  Future<TvShow> getShow(SeriesId id);

  /// Charge les métadonnées de base d'une série sans les épisodes (pour affichage rapide).
  Future<TvShow> getShowLite(SeriesId id);

  Future<List<Season>> getSeasons(SeriesId id);
  Future<List<Episode>> getEpisodes(SeriesId id, SeasonId seasonId);
  Future<List<TvShowSummary>> getFeaturedShows();
  Future<List<TvShowSummary>> getUserWatchlist();
  Future<List<TvShowSummary>> getContinueWatching();
  Future<List<TvShowSummary>> searchShows(String query);
  Future<bool> isInWatchlist(SeriesId id);
  Future<void> setWatchlist(SeriesId id, {required bool saved});

  /// Supprime le cache des métadonnées d'une série pour forcer le rechargement.
  Future<void> refreshMetadata(SeriesId id);
}
