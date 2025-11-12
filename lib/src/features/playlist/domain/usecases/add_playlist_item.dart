import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class AddPlaylistItem {
  const AddPlaylistItem(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({
    required PlaylistId playlistId,
    required PlaylistItem item,
  }) {
    return _repository.addItem(playlistId: playlistId, item: item);
  }
}
