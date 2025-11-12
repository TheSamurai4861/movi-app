import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

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
