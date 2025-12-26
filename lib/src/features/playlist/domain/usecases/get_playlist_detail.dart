import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class GetPlaylistDetail {
  const GetPlaylistDetail(this._repository);

  final PlaylistRepository _repository;

  Future<Playlist> call(PlaylistId id) => _repository.getPlaylist(id);
}
