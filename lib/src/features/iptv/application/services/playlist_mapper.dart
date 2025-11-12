import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';

class PlaylistMapper {
  const PlaylistMapper();

  List<XtreamPlaylist> buildPlaylists({
    required String accountId,
    required Iterable<XtreamCategoryDto> movieCategories,
    required Iterable<XtreamStreamDto> movieStreams,
    required Iterable<XtreamCategoryDto> seriesCategories,
    required Iterable<XtreamStreamDto> seriesStreams,
  }) {
    final moviePlaylists = _buildPlaylistGroup(
      accountId: accountId,
      categories: movieCategories,
      streams: movieStreams,
      type: XtreamPlaylistType.movies,
      itemType: XtreamPlaylistItemType.movie,
    );
    final seriesPlaylists = _buildPlaylistGroup(
      accountId: accountId,
      categories: seriesCategories,
      streams: seriesStreams,
      type: XtreamPlaylistType.series,
      itemType: XtreamPlaylistItemType.series,
    );
    return [...moviePlaylists, ...seriesPlaylists];
  }

  List<XtreamPlaylist> _buildPlaylistGroup({
    required String accountId,
    required Iterable<XtreamCategoryDto> categories,
    required Iterable<XtreamStreamDto> streams,
    required XtreamPlaylistType type,
    required XtreamPlaylistItemType itemType,
  }) {
    final categoryById = {for (final cat in categories) cat.id: cat};
    final grouped = <String, List<XtreamPlaylistItem>>{};

    for (final stream in streams) {
      final category = categoryById[stream.categoryId];
      final categoryName = category?.name ?? 'Sans catégorie';
      grouped.putIfAbsent(stream.categoryId, () => []);
      grouped[stream.categoryId]!.add(
        XtreamPlaylistItem(
          accountId: accountId,
          categoryId: stream.categoryId,
          categoryName: categoryName,
          streamId: stream.streamId,
          title: stream.name,
          type: itemType,
          overview: stream.plot,
          posterUrl: stream.streamIcon,
          rating: stream.rating ?? stream.rating5Based,
          releaseYear: _parseYear(stream.released),
          tmdbId: stream.tmdbId,
        ),
      );
    }

    return grouped.entries
        .map(
          (entry) => XtreamPlaylist(
            id: '${accountId}_${type.name}_${entry.key}',
            accountId: accountId,
            title: categoryById[entry.key]?.name ?? 'Autres',
            type: type,
            items: entry.value,
          ),
        )
        .toList(growable: false);
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.length < 4) return null;
    final year = int.tryParse(raw.substring(0, 4));
    return year;
  }
}
