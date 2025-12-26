import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class SetPlaylistPinned {
  const SetPlaylistPinned(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({
    required PlaylistId id,
    required bool isPinned,
  }) {
    return _repository.setPinned(id: id, isPinned: isPinned);
  }
}

