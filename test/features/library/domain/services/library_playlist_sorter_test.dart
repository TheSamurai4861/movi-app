import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/library/domain/services/library_playlist_sorter.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  group('LibraryPlaylistSorter', () {
    test('title trie par titre insensible à la casse', () {
      final a = ContentReference(
        id: '1',
        title: MediaTitle('Zebra'),
        type: ContentType.movie,
      );
      final b = ContentReference(
        id: '2',
        title: MediaTitle('alpha'),
        type: ContentType.movie,
      );
      final out = LibraryPlaylistSorter.sort(
        [a, b],
        sortType: LibraryPlaylistSortType.title,
      );
      expect(out.map((e) => e.title.value), ['alpha', 'Zebra']);
    });

    test('recentlyAdded utilise librarySortTime si pas de playlistItems', () {
      final old = ContentReference(
        id: '1',
        title: MediaTitle('Old'),
        type: ContentType.movie,
        librarySortTime: DateTime(2020),
      );
      final recent = ContentReference(
        id: '2',
        title: MediaTitle('Recent'),
        type: ContentType.movie,
        librarySortTime: DateTime(2024),
      );
      final out = LibraryPlaylistSorter.sort(
        [old, recent],
        sortType: LibraryPlaylistSortType.recentlyAdded,
      );
      expect(out.first.id, '2');
    });

    test('recentlyAdded préfère playlistItems quand fourni', () {
      final refA = ContentReference(
        id: 'a',
        title: MediaTitle('A'),
        type: ContentType.movie,
        librarySortTime: DateTime(2024),
      );
      final refB = ContentReference(
        id: 'b',
        title: MediaTitle('B'),
        type: ContentType.movie,
        librarySortTime: DateTime(2020),
      );
      final items = [
        PlaylistItem(
          reference: refA,
          addedAt: DateTime(2010),
        ),
        PlaylistItem(
          reference: refB,
          addedAt: DateTime(2025),
        ),
      ];
      final out = LibraryPlaylistSorter.sort(
        [refA, refB],
        sortType: LibraryPlaylistSortType.recentlyAdded,
        playlistItems: items,
      );
      expect(out.first.id, 'b');
    });
  });
}
