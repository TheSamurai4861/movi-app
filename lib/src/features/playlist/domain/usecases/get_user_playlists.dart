import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

class GetUserPlaylists {
  const GetUserPlaylists(this._repository);

  final PlaylistRepository _repository;

  Future<List<PlaylistSummary>> call(String userId) =>
      _repository.getUserPlaylists(userId);
}
