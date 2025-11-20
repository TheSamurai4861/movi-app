import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/repositories/playlist_local_repository.dart';
import 'package:movi/src/features/playlist/data/repositories/playlist_repository_impl.dart';

class _FakePlaylistLocalRepository extends PlaylistLocalRepository {
  List<PlaylistHeader> headers = [];

  @override
  Future<List<PlaylistHeader>> getMostRecentlyUpdated(int limit) async {
    final sorted = [...headers]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }
}

void main() {
  group('getFeaturedPlaylists', () {
    test('applies limit and preserves ordering by updatedAt DESC', () async {
      final local = _FakePlaylistLocalRepository();
      local.headers = [
        PlaylistHeader(
          id: 'pl1',
          title: 'One',
          description: null,
          cover: null,
          owner: 'u',
          isPublic: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        PlaylistHeader(
          id: 'pl2',
          title: 'Two',
          description: null,
          cover: null,
          owner: 'u',
          isPublic: false,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 2, 1),
        ),
        PlaylistHeader(
          id: 'pl3',
          title: 'Three',
          description: null,
          cover: null,
          owner: 'u',
          isPublic: false,
          createdAt: DateTime(2024, 1, 3),
          updatedAt: DateTime(2024, 3, 1),
        ),
      ];

      final repo = PlaylistRepositoryImpl(local);

      final featured = await repo.getFeaturedPlaylists();

      expect(featured.length, 3);
      expect(featured[0].title.value, 'Three');
      expect(featured[1].title.value, 'Two');
      expect(featured[2].title.value, 'One');
    });

    test('caps at 10 items', () async {
      final local = _FakePlaylistLocalRepository();
      local.headers = List.generate(
        25,
        (i) => PlaylistHeader(
          id: 'pl$i',
          title: 'Title $i',
          description: null,
          cover: null,
          owner: 'u',
          isPublic: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1).add(Duration(days: i)),
        ),
      );
      final repo = PlaylistRepositoryImpl(local);

      final featured = await repo.getFeaturedPlaylists();
      expect(featured.length, 10);
      // Latest should be first
      expect(featured.first.title.value, 'Title 24');
    });
  });
}