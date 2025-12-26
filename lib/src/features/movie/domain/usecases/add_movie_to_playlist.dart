import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class AddMovieToPlaylist {
  const AddMovieToPlaylist(this._playlists);

  final PlaylistRepository _playlists;

  Future<void> call({
    required String playlistId,
    required String movieId,
    required String title,
    Uri? poster,
    int? year,
  }) {
    return _playlists.addItem(
      playlistId: PlaylistId(playlistId),
      item: PlaylistItem(
        reference: ContentReference(
          id: movieId,
          title: MediaTitle(title),
          type: ContentType.movie,
          poster: poster,
          year: year,
        ),
        addedAt: DateTime.now(),
      ),
    );
  }
}
