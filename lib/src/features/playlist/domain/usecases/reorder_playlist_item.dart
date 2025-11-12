import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class ReorderPlaylistItem {
  const ReorderPlaylistItem(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({
    required PlaylistId playlistId,
    required int fromPosition,
    required int toPosition,
  }) {
    return _repository.reorderItem(
      playlistId: playlistId,
      fromPosition: fromPosition,
      toPosition: toPosition,
    );
  }
}
