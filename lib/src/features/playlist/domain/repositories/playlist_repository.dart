import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

/// Contract for playlist operations in the Domain layer.
///
/// Implementations must remain infrastructure-agnostic and enforce clear
/// business rules (e.g., fail when adding to a non-existent playlist).
abstract class PlaylistRepository {
  /// Returns a full playlist by its identifier.
  Future<Playlist> getPlaylist(PlaylistId id);
  /// Returns playlists owned by a given user, ordered by last update when possible.
  Future<List<PlaylistSummary>> getUserPlaylists(String userId);
  /// Returns featured playlists, typically the most recently updated.
  Future<List<PlaylistSummary>> getFeaturedPlaylists();
  /// Performs a title-based search over playlists.
  Future<List<PlaylistSummary>> searchPlaylists(String query);
  /// Creates a new playlist header with the provided metadata.
  Future<void> createPlaylist({
    required PlaylistId id,
    required MediaTitle title,
    String? description,
    Uri? cover,
    required String owner,
    bool isPublic = false,
  });
  /// Renames an existing playlist.
  Future<void> renamePlaylist({
    required PlaylistId id,
    required MediaTitle title,
  });
  /// Deletes a playlist and all its items.
  Future<void> deletePlaylist(PlaylistId id);
  /// Updates the owner of a playlist.
  Future<void> setOwner({required PlaylistId id, required String owner});

  /// Pins/unpins a playlist for quicker access in the Library.
  Future<void> setPinned({required PlaylistId id, required bool isPinned});
  /// Adds an item to a playlist.
  ///
  /// Implementations should throw if the playlist header does not exist
  /// and must apply a deterministic position strategy when missing.
  Future<void> addItem({
    required PlaylistId playlistId,
    required PlaylistItem item,
  });
  /// Removes an item from a playlist, typically by its position.
  Future<void> removeItem({
    required PlaylistId playlistId,
    required PlaylistItem item,
  });
  /// Reorders an item from one position to another, normalizing as needed.
  Future<void> reorderItem({
    required PlaylistId playlistId,
    required int fromPosition,
    required int toPosition,
  });

  /// Normalizes item positions to a contiguous sequence starting at 1.
  Future<void> normalizePositions(PlaylistId id);
}
