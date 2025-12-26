import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';

class SearchPlaylists {
  const SearchPlaylists(this._repository);

  final PlaylistRepository _repository;

  Future<List<PlaylistSummary>> call(String query) =>
      _repository.searchPlaylists(query.trim());
}
