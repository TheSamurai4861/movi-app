import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/playlist/domain/usecases/search_playlists.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _FakePlaylistRepository implements PlaylistRepository {
  String? lastQuery;

  @override
  Future<List<PlaylistSummary>> searchPlaylists(String query) async {
    lastQuery = query;
    return [];
  }

  // Unused
  @override
  Future<Playlist> getPlaylist(PlaylistId id) async => throw UnimplementedError();
  @override
  Future<List<PlaylistSummary>> getFeaturedPlaylists() async => throw UnimplementedError();
  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async => throw UnimplementedError();
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
  test('SearchPlaylists trims query before delegating', () async {
    final repo = _FakePlaylistRepository();
    final usecase = SearchPlaylists(repo);
    await usecase.call('  hello  ');
    expect(repo.lastQuery, 'hello');
  });
}