import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

class RemovePlaylistItem {
  const RemovePlaylistItem(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({required PlaylistId playlistId, required PlaylistItem item}) {
    return _repository.removeItem(playlistId: playlistId, item: item);
  }
}
