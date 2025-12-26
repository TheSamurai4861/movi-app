import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class CreatePlaylist {
  const CreatePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call({
    required PlaylistId id,
    required MediaTitle title,
    String? description,
    Uri? cover,
    required String owner,
    bool isPublic = false,
  }) {
    return _repository.createPlaylist(
      id: id,
      title: title,
      description: description,
      cover: cover,
      owner: owner,
      isPublic: isPublic,
    );
  }
}
