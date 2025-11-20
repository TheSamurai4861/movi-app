import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/playlist/domain/usecases/get_featured_playlists.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class _FakePlaylistRepository implements PlaylistRepository {
  List<PlaylistSummary> featured = [];

  @override
  Future<List<PlaylistSummary>> getFeaturedPlaylists() async => featured;

  // Unused for this test
  @override
  Future<Playlist> getPlaylist(PlaylistId id) async => throw UnimplementedError();
  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async => throw UnimplementedError();
  @override
  Future<List<PlaylistSummary>> searchPlaylists(String query) async => throw UnimplementedError();
  @override
  Future<void> createPlaylist({required PlaylistId id, required MediaTitle title, String? description, Uri? cover, required String owner, bool isPublic = false}) async {}
  @override
  Future<void> renamePlaylist({required PlaylistId id, required MediaTitle title}) async {}
  @override
  Future<void> deletePlaylist(PlaylistId id) async {}
  @override
  Future<void> setOwner({required PlaylistId id, required String owner}) async {}
  @override
  Future<void> addItem({required PlaylistId playlistId, required PlaylistItem item}) async {}
  @override
  Future<void> removeItem({required PlaylistId playlistId, required PlaylistItem item}) async {}
  @override
  Future<void> reorderItem({required PlaylistId playlistId, required int fromPosition, required int toPosition}) async {}
  @override
  Future<void> normalizePositions(PlaylistId id) async {}
}

void main() {
  test('GetFeaturedPlaylists returns repository results', () async {
    final repo = _FakePlaylistRepository();
    repo.featured = [
      PlaylistSummary(id: PlaylistId('a'), title: MediaTitle('A')),
      PlaylistSummary(id: PlaylistId('b'), title: MediaTitle('B')),
    ];
    final usecase = GetFeaturedPlaylists(repo);
    final result = await usecase.call();
    expect(result.length, 2);
    expect(result[0].title.value, 'A');
    expect(result[1].title.value, 'B');
  });
}