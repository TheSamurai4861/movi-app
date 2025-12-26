import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';

class FilterRecommendationsByIptvAvailability {
  const FilterRecommendationsByIptvAvailability(this._iptvLocal);

  final IptvLocalRepository _iptvLocal;

  Future<List<MovieSummary>> call(List<MovieSummary> recommendations) async {
    final available = await _iptvLocal.getAvailableTmdbIds(
      type: XtreamPlaylistItemType.movie,
    );
    if (available.isEmpty) return const <MovieSummary>[];
    return recommendations
        .where((m) => m.tmdbId != null && available.contains(m.tmdbId!))
        .toList(growable: false);
  }
}
