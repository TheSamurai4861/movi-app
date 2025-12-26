import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/data/dtos/stalker_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/stalker_stream_dto.dart';

/// Mapper pour convertir les DTOs Stalker en XtreamPlaylist/XtreamPlaylistItem
/// Réutilise les entités Xtream* existantes pour maintenir la compatibilité
class StalkerPlaylistMapper {
  const StalkerPlaylistMapper();

  List<XtreamPlaylist> buildPlaylists({
    required String accountId,
    required Iterable<StalkerCategoryDto> movieCategories,
    required Iterable<StalkerStreamDto> movieStreams,
    required Iterable<StalkerCategoryDto> seriesCategories,
    required Iterable<StalkerStreamDto> seriesStreams,
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
    required Iterable<StalkerCategoryDto> categories,
    required Iterable<StalkerStreamDto> streams,
    required XtreamPlaylistType type,
    required XtreamPlaylistItemType itemType,
  }) {
    final categoryById = {for (final cat in categories) cat.id: cat};
    final grouped = <String, List<XtreamPlaylistItem>>{};

    for (final stream in streams) {
      // Utilise la catégorie du stream ou "01" (All) par défaut
      final categoryId = stream.categoryId.isNotEmpty ? stream.categoryId : '01';
      grouped.putIfAbsent(categoryId, () => []);
      grouped[categoryId]!.add(
        _toPlaylistItem(
          accountId: accountId,
          stream: stream,
          itemType: itemType,
          categoryById: categoryById,
        ),
      );
    }

    return grouped.entries
        .map(
          (entry) => XtreamPlaylist(
            id: '${accountId}_${type.name}_${entry.key}',
            accountId: accountId,
            title: categoryById[entry.key]?.title ?? 'Autres',
            type: type,
            items: entry.value,
          ),
        )
        .toList(growable: false);
  }

  XtreamPlaylistItem _toPlaylistItem({
    required String accountId,
    required StalkerStreamDto stream,
    required XtreamPlaylistItemType itemType,
    required Map<String, StalkerCategoryDto> categoryById,
  }) {
    final category = categoryById[stream.categoryId];
    final categoryName = category?.title ?? 'Sans catégorie';
    return XtreamPlaylistItem(
      accountId: accountId,
      categoryId: stream.categoryId,
      categoryName: categoryName,
      streamId: stream.streamId,
      title: stream.name,
      type: itemType,
      overview: stream.plot,
      posterUrl: stream.streamIcon,
      containerExtension: null, // Stalker ne fournit pas toujours cette info
      rating: stream.rating,
      releaseYear: stream.year ?? _parseYear(stream.released),
      tmdbId: stream.tmdbId,
    );
  }

  int? _parseYear(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    // Peut être au format "2021-12-20 21:17:25" ou "06/11/2025"
    if (raw.length >= 4) {
      // Essaie d'extraire l'année du début
      final year = int.tryParse(raw.substring(0, 4));
      if (year != null && year > 1900 && year < 2100) {
        return year;
      }
    }
    // Essaie de parser comme date complète
    try {
      final date = DateTime.tryParse(raw);
      if (date != null) {
        return date.year;
      }
    } catch (_) {
      // Ignore
    }
    return null;
  }
}

