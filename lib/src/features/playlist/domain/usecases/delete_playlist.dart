import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class DeletePlaylist {
  const DeletePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call(PlaylistId id) => _repository.deletePlaylist(id);
}
