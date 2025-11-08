import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/playlist/data/repositories/playlist_repository_impl.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/storage/repositories/playlist_local_repository.dart';

import '../../../helpers/database_initializer.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test('create, map detail, rename, reorder, delete', () async {
    final local = PlaylistLocalRepository();
    final repo = PlaylistRepositoryImpl(local);

    final id = PlaylistId('pl42');
    await repo.createPlaylist(
      id: id,
      title: MediaTitle('My Mix'),
      description: null,
      cover: null,
      owner: 'user-42',
    );

    await repo.addItem(
      playlistId: id,
      item: PlaylistItem(
        reference: ContentReference(
          id: '550',
          title: MediaTitle('Fight Club'),
          type: ContentType.movie,
        ),
        position: 1,
      ),
    );
    await repo.addItem(
      playlistId: id,
      item: PlaylistItem(
        reference: ContentReference(
          id: '1399',
          title: MediaTitle('GOT'),
          type: ContentType.series,
        ),
        position: 2,
      ),
    );

    var detail = await repo.getPlaylist(id);
    expect(detail.title.value, 'My Mix');
    expect(detail.items.length, 2);
    expect(detail.items.first.reference.id, '550');

    await repo.renamePlaylist(id: id, title: MediaTitle('Renamed'));
    detail = await repo.getPlaylist(id);
    expect(detail.title.value, 'Renamed');

    await repo.reorderItem(playlistId: id, fromPosition: 1, toPosition: 2);
    detail = await repo.getPlaylist(id);
    expect(detail.items.first.reference.id, '1399');

    await repo.deletePlaylist(id);
    expect(() => repo.getPlaylist(id), throwsA(isA<StateError>()));
  });
}
