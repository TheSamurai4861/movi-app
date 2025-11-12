import 'package:movi/src/features/playlist/domain/entities/playlist.dart';

class PlaylistOrderingService {
  const PlaylistOrderingService();

  Playlist normalizePositions(Playlist playlist) {
    final items = [...playlist.items];
    items.sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    final normalized = <PlaylistItem>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      normalized.add(
        PlaylistItem(
          reference: item.reference,
          position: i + 1,
          addedAt: item.addedAt,
          runtime: item.runtime,
          notes: item.notes,
        ),
      );
    }
    return Playlist(
      id: playlist.id,
      title: playlist.title,
      description: playlist.description,
      cover: playlist.cover,
      items: normalized,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      owner: playlist.owner,
      isPublic: playlist.isPublic,
      totalDuration: playlist.totalDuration,
    );
  }
}
