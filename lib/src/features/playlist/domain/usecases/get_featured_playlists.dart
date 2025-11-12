import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';

class GetFeaturedPlaylists {
  const GetFeaturedPlaylists(this._repository);

  final PlaylistRepository _repository;

  Future<List<PlaylistSummary>> call() => _repository.getFeaturedPlaylists();
}
