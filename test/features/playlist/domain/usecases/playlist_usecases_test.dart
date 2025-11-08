import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/usecases/create_playlist.dart';
import 'package:movi/src/features/playlist/domain/usecases/rename_playlist.dart';
import 'package:movi/src/features/playlist/domain/usecases/delete_playlist.dart';
import 'package:movi/src/features/playlist/domain/usecases/reorder_playlist_item.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _PlaylistRepoSpy implements PlaylistRepository {
  final List<String> calls = [];

  @override
  Future<void> createPlaylist({
    required PlaylistId id,
    required MediaTitle title,
    String? description,
    Uri? cover,
    required String owner,
    bool isPublic = false,
  }) async {
    calls.add('create:${id.value}:${title.value}:$owner:$isPublic');
  }

  @override
  Future<void> renamePlaylist({required PlaylistId id, required MediaTitle title}) async {
    calls.add('rename:${id.value}:${title.value}');
  }

  @override
  Future<void> deletePlaylist(PlaylistId id) async {
    calls.add('delete:${id.value}');
  }

  @override
  Future<void> reorderItem({required PlaylistId playlistId, required int fromPosition, required int toPosition}) async {
    calls.add('reorder:${playlistId.value}:$fromPosition:$toPosition');
  }

  // Unused for these tests
  @override
  Future<void> addItem({required PlaylistId playlistId, required PlaylistItem item}) async {}
  @override
  Future<Playlist> getPlaylist(PlaylistId id) async => throw UnimplementedError();
  @override
  Future<List<PlaylistSummary>> getFeaturedPlaylists() async => const [];
  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async => const [];
  @override
  Future<void> removeItem({required PlaylistId playlistId, required PlaylistItem item}) async {}
  @override
  Future<List<PlaylistSummary>> searchPlaylists(String query) async => const [];
  @override
  Future<void> setOwner({required PlaylistId id, required String owner}) async {}
}

void main() {
  test('Create/Rename/Delete/Reorder use cases delegate to repository', () async {
    final repo = _PlaylistRepoSpy();

    await CreatePlaylist(repo)(
      id: const PlaylistId('pl1'),
      title: MediaTitle('My Mix'),
      owner: 'user-1',
    );
    await RenamePlaylist(repo)(id: const PlaylistId('pl1'), title: MediaTitle('New Name'));
    await ReorderPlaylistItem(repo)(playlistId: const PlaylistId('pl1'), fromPosition: 1, toPosition: 2);
    await DeletePlaylist(repo)(const PlaylistId('pl1'));

    expect(repo.calls, [
      'create:pl1:My Mix:user-1:false',
      'rename:pl1:New Name',
      'reorder:pl1:1:2',
      'delete:pl1',
    ]);
  });
}
