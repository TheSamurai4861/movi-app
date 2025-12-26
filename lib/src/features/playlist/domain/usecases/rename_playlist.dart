import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class RenamePlaylist {
  const RenamePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({required PlaylistId id, required MediaTitle title}) {
    return _repository.renamePlaylist(id: id, title: title);
  }
}
