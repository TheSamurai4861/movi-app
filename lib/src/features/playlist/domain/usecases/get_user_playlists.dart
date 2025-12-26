import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';

class GetUserPlaylists {
  const GetUserPlaylists(this._repository);

  final PlaylistRepository _repository;

  Future<List<PlaylistSummary>> call(String userId) =>
      _repository.getUserPlaylists(userId);
}
