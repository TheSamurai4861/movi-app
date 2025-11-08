import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

class GetFeaturedPlaylists {
  const GetFeaturedPlaylists(this._repository);

  final PlaylistRepository _repository;

  Future<List<PlaylistSummary>> call() => _repository.getFeaturedPlaylists();
}
