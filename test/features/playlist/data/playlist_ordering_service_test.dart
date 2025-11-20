import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/playlist/data/services/playlist_ordering_service.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  group('PlaylistOrderingService.normalizePositions', () {
    test('orders by position and renumbers 1..n', () {
      final service = const PlaylistOrderingService();
      final playlist = Playlist(
        id: PlaylistId('pl'),
        title: MediaTitle('T'),
        items: [
          PlaylistItem(
            reference: ContentReference(
              id: '1',
              title: MediaTitle('A'),
              type: ContentType.movie,
            ),
            position: 5,
          ),
          PlaylistItem(
            reference: ContentReference(
              id: '2',
              title: MediaTitle('B'),
              type: ContentType.movie,
            ),
            position: 2,
          ),
          PlaylistItem(
            reference: ContentReference(
              id: '3',
              title: MediaTitle('C'),
              type: ContentType.movie,
            ),
            position: null,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        owner: 'u',
        isPublic: false,
      );

      final normalized = service.normalizePositions(playlist);
      expect(normalized.items.length, 3);
      expect(normalized.items[0].position, 1);
      expect(normalized.items[1].position, 2);
      expect(normalized.items[2].position, 3);
    });

    test('idempotent on already normalized list', () {
      final service = const PlaylistOrderingService();
      final normalized = Playlist(
        id: PlaylistId('pl'),
        title: MediaTitle('T'),
        items: [
          PlaylistItem(
            reference: ContentReference(
              id: '1',
              title: MediaTitle('A'),
              type: ContentType.movie,
            ),
            position: 1,
          ),
          PlaylistItem(
            reference: ContentReference(
              id: '2',
              title: MediaTitle('B'),
              type: ContentType.movie,
            ),
            position: 2,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        owner: 'u',
        isPublic: false,
      );
      final result = service.normalizePositions(normalized);
      expect(result.items[0].position, 1);
      expect(result.items[1].position, 2);
    });

    test('handles large lists efficiently (>1000 items)', () {
      final service = const PlaylistOrderingService();
      final items = List.generate(
        1500,
        (i) => PlaylistItem(
          reference: ContentReference(
            id: '${i + 1}',
            title: MediaTitle('I${i + 1}'),
            type: ContentType.movie,
          ),
          position: i % 3 == 0 ? null : i,
        ),
      );
      final playlist = Playlist(
        id: PlaylistId('pl'),
        title: MediaTitle('T'),
        items: items,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        owner: 'u',
        isPublic: false,
      );
      final normalized = service.normalizePositions(playlist);
      expect(normalized.items.length, 1500);
      expect(normalized.items.first.position, 1);
      expect(normalized.items.last.position, 1500);
    });
  });
}