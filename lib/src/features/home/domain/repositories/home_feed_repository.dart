import 'package:dio/dio.dart';

import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Contract for the Home feed data needed by the Home page (no UI).
abstract class HomeFeedRepository {
  /// Trending movies + TV shows on TMDB intersected with IPTV availability.
  ///
  /// Returned items are ordered for the hero carousel.
  Future<Result<List<ContentReference>, Failure>> getHeroItems();

  /// Trending movies from TMDB (page 1) without IPTV intersection.
  /// Used for kid profiles to filter by age and paginate.
  Future<Result<List<ContentReference>, Failure>> getTrendingMoviesPage(int page);

  /// Trending series from TMDB (page 1) without IPTV intersection.
  /// Used for kid profiles to filter by age and paginate.
  Future<Result<List<ContentReference>, Failure>> getTrendingSeriesPage(int page);

  /// Local-only continue watching for movies.
  Future<List<MovieSummary>> getContinueWatchingMovies();

  /// Local-only continue watching for TV shows.
  Future<List<TvShowSummary>> getContinueWatchingShows();

  /// IPTV categories aggregated by account alias and category name.
  /// Key format: `<accountAlias>/<categoryName>`.
  ///
  /// IMPORTANT:
  /// - Chaque section ne doit pré-enrichir que les 5 premiers éléments.
  /// - Le reste est "léger" (pas d'appel TMDB ici).
  Future<Result<Map<String, List<ContentReference>>, Failure>>
  getIptvCategoryLists({int? itemLimitPerPlaylist});

  /// Enrichit un ContentReference “léger” avec les métadonnées TMDB (poster TMDB,
  /// year, rating) via cache->réseau si nécessaire, puis renvoie une copie complète.
  Future<ContentReference> enrichReference(
    ContentReference ref, {
    CancelToken? cancelToken,
  });
}
