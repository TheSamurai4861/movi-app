import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Cross-feature application service that filters playlist items based on IPTV availability.
///
/// Keeps Domain types (`Playlist`, `ContentReference`) at the boundary and
/// delegates availability queries to `IptvLocalRepository`.
class PlaylistFilterService {
  const PlaylistFilterService(this._iptvLocal);

  final IptvLocalRepository _iptvLocal;

  /// Returns a new playlist containing only items available on IPTV.
  Future<Playlist> filterUnavailable(Playlist playlist) async {
    final movieIds = await _iptvLocal.getAvailableTmdbIds(
      type: XtreamPlaylistItemType.movie,
    );
    final showIds = await _iptvLocal.getAvailableTmdbIds(
      type: XtreamPlaylistItemType.series,
    );
    final filtered = playlist.items.where((i) {
      final type = i.reference.type;
      final id = int.tryParse(i.reference.id);
      if (id == null) return false;
      if (type == ContentType.movie) return movieIds.contains(id);
      if (type == ContentType.series) return showIds.contains(id);
      return true; // keep others (e.g., saga, playlist) by default
    }).toList();
    return Playlist(
      id: playlist.id,
      title: playlist.title,
      description: playlist.description,
      cover: playlist.cover,
      items: filtered,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      owner: playlist.owner,
      isPublic: playlist.isPublic,
      totalDuration: playlist.totalDuration,
    );
  }
}