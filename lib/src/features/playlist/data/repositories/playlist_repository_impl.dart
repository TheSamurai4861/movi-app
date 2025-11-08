import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';
import '../../../../shared/domain/value_objects/media_title.dart';
import '../../../../shared/domain/value_objects/synopsis.dart';
import '../../../../core/storage/repositories/playlist_local_repository.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(this._local);

  final PlaylistLocalRepository _local;

  @override
  Future<void> createPlaylist({
    required PlaylistId id,
    required MediaTitle title,
    String? description,
    Uri? cover,
    required String owner,
    bool isPublic = false,
  }) async {
    await _local.createPlaylist(
      PlaylistHeader(
        id: id.value,
        title: title.value,
        description: description,
        cover: cover,
        owner: owner,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> renamePlaylist({required PlaylistId id, required MediaTitle title}) async {
    await _local.renamePlaylist(id.value, title.value);
  }

  @override
  Future<void> deletePlaylist(PlaylistId id) => _local.deletePlaylist(id.value);

  @override
  Future<void> setOwner({required PlaylistId id, required String owner}) => _local.setOwner(id.value, owner);

  @override
  Future<void> addItem({required PlaylistId playlistId, required PlaylistItem item}) async {
    final header = await _local.getPlaylist(playlistId.value);
    if (header == null) {
      // Create playlist header if missing (owner unknown: fallback to 'local')
      await _local.upsertHeader(
        PlaylistHeader(
          id: playlistId.value,
          title: 'Playlist',
          description: null,
          cover: null,
          owner: 'local',
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    await _local.addItem(
      playlistId.value,
      PlaylistItemRow(
        position: item.position ?? DateTime.now().millisecondsSinceEpoch, // naive ordering if missing
        reference: item.reference,
        runtime: item.runtime,
        notes: item.notes,
        addedAt: item.addedAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Future<Playlist> getPlaylist(PlaylistId id) async {
    final detail = await _local.getPlaylist(id.value);
    if (detail == null) {
      throw StateError('Playlist ${id.value} not found');
    }
    return _mapDetail(detail);
  }

  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async {
    final headers = await _local.getUserPlaylists(userId);
    return headers
        .map(
          (h) => PlaylistSummary(
            id: PlaylistId(h.id),
            title: MediaTitle(h.title),
            cover: h.cover,
            itemCount: null,
            owner: h.owner,
          ),
        )
        .toList();
  }

  @override
  Future<List<PlaylistSummary>> getFeaturedPlaylists() async {
    // Use most recently updated playlists as featured
    final headers = await _local.searchByTitle('');
    return headers
        .take(10)
        .map(
          (h) => PlaylistSummary(
            id: PlaylistId(h.id),
            title: MediaTitle(h.title),
            cover: h.cover,
            itemCount: null,
            owner: h.owner,
          ),
        )
        .toList();
  }

  @override
  Future<void> removeItem({required PlaylistId playlistId, required PlaylistItem item}) async {
    final position = item.position;
    if (position == null) return;
    await _local.removeItem(playlistId.value, position);
  }

  @override
  Future<void> reorderItem({required PlaylistId playlistId, required int fromPosition, required int toPosition}) {
    return _local.reorderItem(playlistId.value, fromPosition: fromPosition, toPosition: toPosition);
  }

  @override
  Future<List<PlaylistSummary>> searchPlaylists(String query) async {
    final headers = await _local.searchByTitle(query);
    return headers
        .map((h) => PlaylistSummary(
              id: PlaylistId(h.id),
              title: MediaTitle(h.title),
              cover: h.cover,
              itemCount: null,
              owner: h.owner,
            ))
        .toList();
  }

  Playlist _mapDetail(PlaylistDetailRow detail) {
    return Playlist(
      id: PlaylistId(detail.header.id),
      title: MediaTitle(detail.header.title),
      description: detail.header.description != null ? Synopsis(detail.header.description!) : null,
      cover: detail.header.cover,
      items: detail.items
          .map(
            (i) => PlaylistItem(
              reference: i.reference,
              position: i.position,
              addedAt: i.addedAt,
              runtime: i.runtime,
              notes: i.notes,
            ),
          )
          .toList(),
      createdAt: detail.header.createdAt,
      updatedAt: detail.header.updatedAt,
      owner: detail.header.owner,
      isPublic: detail.header.isPublic,
      totalDuration: detail.items.fold<Duration?>(
        null,
        (acc, i) => i.runtime != null ? (acc ?? Duration.zero) + i.runtime! : acc,
      ),
    );
  }
}
