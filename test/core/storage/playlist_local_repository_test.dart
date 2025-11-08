import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/storage/repositories/playlist_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

import '../../helpers/database_initializer.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test('playlist CRUD basic flow', () async {
    final repo = PlaylistLocalRepository();

    final header = PlaylistHeader(
      id: 'pl1',
      title: 'My Playlist',
      description: 'desc',
      cover: Uri.parse('https://image.example/cover.jpg'),
      owner: 'user-1',
      isPublic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.upsertHeader(header);

    await repo.addItem(
      'pl1',
      PlaylistItemRow(
        position: 1,
        reference: ContentReference(
          id: '550',
          title: MediaTitle('Fight Club'),
          type: ContentType.movie,
          poster: Uri.parse('https://image.tmdb.org/t/p/w500/poster.jpg'),
        ),
        runtime: const Duration(minutes: 139),
        notes: 'Great movie',
        addedAt: DateTime.now(),
      ),
    );

    final detail = await repo.getPlaylist('pl1');
    expect(detail, isNotNull);
    expect(detail!.items.length, 1);

    await repo.removeItem('pl1', 1);
    final after = await repo.getPlaylist('pl1');
    expect(after!.items, isEmpty);

    final mine = await repo.getUserPlaylists('user-1');
    expect(mine.length, 1);

    final search = await repo.searchByTitle('My');
    expect(search.length, 1);
  });

  test('reorder with non-consecutive positions renumbers without collisions', () async {
    final repo = PlaylistLocalRepository();

    final header = PlaylistHeader(
      id: 'pl2',
      title: 'Another',
      description: null,
      cover: null,
      owner: 'user-1',
      isPublic: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repo.upsertHeader(header);

    // Insert with gaps: positions 1, 3, 5
    await repo.addItem(
      'pl2',
      PlaylistItemRow(
        position: 1,
        reference: ContentReference(id: '550', title: MediaTitle('A'), type: ContentType.movie),
        runtime: const Duration(minutes: 10),
        notes: null,
        addedAt: DateTime.now(),
      ),
    );
    await repo.addItem(
      'pl2',
      PlaylistItemRow(
        position: 3,
        reference: ContentReference(id: '551', title: MediaTitle('B'), type: ContentType.movie),
        runtime: const Duration(minutes: 10),
        notes: null,
        addedAt: DateTime.now(),
      ),
    );
    await repo.addItem(
      'pl2',
      PlaylistItemRow(
        position: 5,
        reference: ContentReference(id: '552', title: MediaTitle('C'), type: ContentType.movie),
        runtime: const Duration(minutes: 10),
        notes: null,
        addedAt: DateTime.now(),
      ),
    );

    await repo.reorderItem('pl2', fromPosition: 5, toPosition: 1);
    final after = await repo.getPlaylist('pl2');
    expect(after, isNotNull);
    // Should be renumbered to 1..3 without UNIQUE collisions
    expect(after!.items.map((e) => e.position), [1, 2, 3]);
    expect(after.items.first.reference.id, '552');
  });
}
