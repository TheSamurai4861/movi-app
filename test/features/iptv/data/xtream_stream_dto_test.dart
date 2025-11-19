import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';

void main() {
  group('XtreamStreamDto.fromJson', () {
    test('supporte les différentes clés tmdb*', () {
      final dto1 = XtreamStreamDto.fromJson({
        'stream_id': 1,
        'name': 'Test',
        'category_id': '10',
        'tmdb': 123,
      });
      final dto2 = XtreamStreamDto.fromJson({
        'stream_id': 1,
        'name': 'Test',
        'category_id': '10',
        'tmdb_id': '124',
      });
      final dto3 = XtreamStreamDto.fromJson({
        'stream_id': 1,
        'name': 'Test',
        'category_id': '10',
        'tmdbId': '125',
      });
      final dto4 = XtreamStreamDto.fromJson({
        'stream_id': 1,
        'name': 'Test',
        'category_id': '10',
        'tmdbID': '126',
      });

      expect(dto1.tmdbId, 123);
      expect(dto2.tmdbId, 124);
      expect(dto3.tmdbId, 125);
      expect(dto4.tmdbId, 126);
    });

    test('supporte les variantes de stream_id / id / series_id / seriesId', () {
      final dtoStreamId = XtreamStreamDto.fromJson({
        'stream_id': 5,
        'name': 'A',
        'category_id': '1',
      });
      final dtoId = XtreamStreamDto.fromJson({
        'id': '6',
        'name': 'B',
        'category_id': '1',
      });
      final dtoSeriesId = XtreamStreamDto.fromJson({
        'series_id': '7',
        'name': 'C',
        'category_id': '1',
      });
      final dtoSeriesId2 = XtreamStreamDto.fromJson({
        'seriesId': 8,
        'name': 'D',
        'category_id': '1',
      });

      expect(dtoStreamId.streamId, 5);
      expect(dtoId.streamId, 6);
      expect(dtoSeriesId.streamId, 7);
      expect(dtoSeriesId2.streamId, 8);
    });

    test('parse les champs rating et released', () {
      final dto = XtreamStreamDto.fromJson({
        'stream_id': 1,
        'name': 'Test',
        'category_id': '10',
        'rating': '7.5',
        'rating_5based': '4.0',
        'releasedate': '2020-01-15',
      });

      expect(dto.rating, closeTo(7.5, 0.001));
      expect(dto.rating5Based, closeTo(4.0, 0.001));
      expect(dto.released, '2020-01-15');
    });

    test('utilise les fallbacks pour name et categoryId', () {
      final dto = XtreamStreamDto.fromJson({});

      expect(dto.name, 'Untitled');
      expect(dto.categoryId, '');
    });
  });
}
