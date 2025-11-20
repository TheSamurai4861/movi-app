import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/application/services/playlist_mapper.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';

void main() {
  group('PlaylistMapper.buildPlaylists', () {
    const mapper = PlaylistMapper();

    XtreamStreamDto makeStream({
      required int id,
      required String name,
      required String categoryId,
      int? tmdbId,
      String? released,
    }) {
      return XtreamStreamDto.fromJson({
        'stream_id': id,
        'name': name,
        'category_id': categoryId,
        'tmdb': tmdbId,
        'releasedate': released,
      });
    }

    test('construit des playlists films et séries avec catégories', () {
      final movieCategories = [
        XtreamCategoryDto(id: '1', name: 'Movies/Action'),
      ];
      final seriesCategories = [
        XtreamCategoryDto(id: '2', name: 'Series/Drama'),
      ];

      final movieStreams = [
        makeStream(id: 10, name: 'Movie A', categoryId: '1', tmdbId: 100),
        makeStream(id: 11, name: 'Movie B', categoryId: '1'),
      ];
      final seriesStreams = [
        makeStream(id: 20, name: 'Show A', categoryId: '2', tmdbId: 200),
      ];

      final playlists = mapper.buildPlaylists(
        accountId: 'acc1',
        movieCategories: movieCategories,
        movieStreams: movieStreams,
        seriesCategories: seriesCategories,
        seriesStreams: seriesStreams,
      );

      expect(playlists.length, 2);

      final moviesPlaylist = playlists.firstWhere(
        (p) => p.type == XtreamPlaylistType.movies,
      );
      final seriesPlaylist = playlists.firstWhere(
        (p) => p.type == XtreamPlaylistType.series,
      );

      expect(moviesPlaylist.items.length, 2);
      expect(seriesPlaylist.items.length, 1);

      expect(moviesPlaylist.title, 'Movies/Action');
      expect(seriesPlaylist.title, 'Series/Drama');

      final movieItem = moviesPlaylist.items.first;
      expect(movieItem.accountId, 'acc1');
      expect(movieItem.categoryId, '1');
      expect(movieItem.categoryName, 'Movies/Action');
      expect(movieItem.streamId, 10);
      expect(movieItem.title, 'Movie A');
      expect(movieItem.tmdbId, 100);
    });

    test('utilise les fallbacks de noms de catégorie', () {
      final playlists = mapper.buildPlaylists(
        accountId: 'acc1',
        movieCategories: const [],
        movieStreams: [makeStream(id: 10, name: 'Movie A', categoryId: 'X')],
        seriesCategories: const [],
        seriesStreams: const [],
      );

      expect(playlists.length, 1);
      final pl = playlists.first;
      expect(pl.title, 'Autres');
      expect(pl.items.single.categoryName, 'Sans catégorie');
    });
  });
}
