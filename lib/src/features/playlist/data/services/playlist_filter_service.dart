import '../../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../../core/iptv/domain/entities/xtream_playlist_item.dart';
import '../../domain/entities/playlist.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';

class PlaylistFilterService {
  const PlaylistFilterService(this._iptvLocal);

  final IptvLocalRepository _iptvLocal;

  Future<Playlist> filterUnavailable(Playlist playlist) async {
    final movieIds = await _iptvLocal.getAvailableTmdbIds(type: XtreamPlaylistItemType.movie);
    final showIds = await _iptvLocal.getAvailableTmdbIds(type: XtreamPlaylistItemType.series);
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
