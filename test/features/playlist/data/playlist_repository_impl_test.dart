import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/repositories/playlist_local_repository.dart';
import 'package:movi/src/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

class _FakePlaylistLocalRepository extends PlaylistLocalRepository {
  PlaylistDetailRow? _detail;
  PlaylistItemRow? lastAdded;

  void setHeader(PlaylistHeader header) {
    _detail = PlaylistDetailRow(header: header, items: []);
  }

  @override
  Future<PlaylistDetailRow?> getPlaylist(String playlistId) async {
    if (_detail == null) return null;
    if (_detail!.header.id == playlistId) return _detail;
    return null;
  }

  @override
  Future<void> addItem(String playlistId, PlaylistItemRow item) async {
    lastAdded = item;
  }
}

void main() {
  group('PlaylistRepositoryImpl.addItem', () {
    test('throws when header is missing', () async {
      final local = _FakePlaylistLocalRepository();
      final repo = PlaylistRepositoryImpl(local);
      final playlistId = PlaylistId('pl1');
      final item = PlaylistItem(
        reference: ContentReference(
          id: '123',
          title: MediaTitle('Title'),
          type: ContentType.movie,
        ),
      );

      expect(
        () => repo.addItem(playlistId: playlistId, item: item),
        throwsA(isA<StateError>()),
      );
    });

    test('delegates to local when header exists', () async {
      final local = _FakePlaylistLocalRepository();
      local.setHeader(
        PlaylistHeader(
          id: 'pl1',
          title: 'My Playlist',
          description: null,
          cover: null,
          owner: 'u1',
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final repo = PlaylistRepositoryImpl(local);
      final playlistId = PlaylistId('pl1');
      final item = PlaylistItem(
        reference: ContentReference(
          id: '123',
          title: MediaTitle('Title'),
          type: ContentType.movie,
        ),
      );

      await repo.addItem(playlistId: playlistId, item: item);

      expect(local.lastAdded, isNotNull);
      expect(local.lastAdded!.reference.id, '123');
      expect(local.lastAdded!.reference.type, ContentType.movie);
      expect(local.lastAdded!.position, isNotNull);
    });
  });
}