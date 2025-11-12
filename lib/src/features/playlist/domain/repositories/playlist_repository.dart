import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

abstract class PlaylistRepository {
  Future<Playlist> getPlaylist(PlaylistId id);
  Future<List<PlaylistSummary>> getUserPlaylists(String userId);
  Future<List<PlaylistSummary>> getFeaturedPlaylists();
  Future<List<PlaylistSummary>> searchPlaylists(String query);
  Future<void> createPlaylist({
    required PlaylistId id,
    required MediaTitle title,
    String? description,
    Uri? cover,
    required String owner,
    bool isPublic = false,
  });
  Future<void> renamePlaylist({
    required PlaylistId id,
    required MediaTitle title,
  });
  Future<void> deletePlaylist(PlaylistId id);
  Future<void> setOwner({required PlaylistId id, required String owner});
  Future<void> addItem({
    required PlaylistId playlistId,
    required PlaylistItem item,
  });
  Future<void> removeItem({
    required PlaylistId playlistId,
    required PlaylistItem item,
  });
  Future<void> reorderItem({
    required PlaylistId playlistId,
    required int fromPosition,
    required int toPosition,
  });
}
