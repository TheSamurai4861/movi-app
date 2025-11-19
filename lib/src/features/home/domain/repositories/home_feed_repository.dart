import 'package:dio/dio.dart';

import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Contract for the Home feed data needed by the Home page (no UI).
abstract class HomeFeedRepository {
  /// Trending movies on TMDB intersected with IPTV availability.
  Future<Result<List<MovieSummary>, Failure>> getHeroMovies();

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
  getIptvCategoryLists();

  /// Enrichit un ContentReference “léger” avec les métadonnées TMDB (poster TMDB,
  /// year, rating) via cache->réseau si nécessaire, puis renvoie une copie complète.
  Future<ContentReference> enrichReference(
    ContentReference ref, {
    CancelToken? cancelToken,
  });
}
