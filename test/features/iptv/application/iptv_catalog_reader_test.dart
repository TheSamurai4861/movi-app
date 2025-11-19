import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class _FakeIptvLocalRepository implements IptvLocalRepository {
  _FakeIptvLocalRepository({
    List<XtreamAccount>? accounts,
    Map<String, List<XtreamPlaylist>>? playlistsByAccount,
  }) : _accounts = accounts ?? <XtreamAccount>[],
       _playlistsByAccount =
           playlistsByAccount ?? <String, List<XtreamPlaylist>>{};

  final List<XtreamAccount> _accounts;
  final Map<String, List<XtreamPlaylist>> _playlistsByAccount;

  @override
  Future<List<XtreamAccount>> getAccounts() async => _accounts;

  @override
  Future<List<XtreamPlaylist>> getPlaylists(String accountId) async =>
      _playlistsByAccount[accountId] ?? <XtreamPlaylist>[];

  // Méthodes non utilisées par IptvCatalogReader : implémentations vides
  @override
  Future<void> removeAccount(String id) async => throw UnimplementedError();

  @override
  Future<void> saveAccount(XtreamAccount account) async =>
      throw UnimplementedError();

  @override
  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async => throw UnimplementedError();

  @override
  Future<Set<int>> getAvailableTmdbIds({XtreamPlaylistItemType? type}) async =>
      throw UnimplementedError();

  @override
  Future<void> saveEpisodes({
    required String accountId,
    required int seriesId,
    required Map<int, Map<int, EpisodeData>> episodes,
  }) async => throw UnimplementedError();

  @override
  Future<int?> getEpisodeId({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async => throw UnimplementedError();

  @override
  Future<EpisodeData?> getEpisodeData({
    required String accountId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
  }) async => throw UnimplementedError();

  @override
  Future<Map<int, Map<int, EpisodeData>>> getAllEpisodesForSeries({
    required String accountId,
    required int seriesId,
  }) async => throw UnimplementedError();
}

void main() {
  group('IptvCatalogReader', () {
    final account = XtreamAccount(
      id: 'acc1',
      alias: 'Main',
      endpoint: XtreamEndpoint.parse('http://example.com'),
      username: 'user',
      status: XtreamAccountStatus.active,
      createdAt: DateTime(2020, 1, 1),
    );

    XtreamPlaylist _playlist(
      String id,
      String title,
      List<XtreamPlaylistItem> items,
    ) {
      return XtreamPlaylist(
        id: id,
        accountId: account.id,
        title: title,
        type: XtreamPlaylistType.movies,
        items: items,
      );
    }

    XtreamPlaylistItem _item({
      required int streamId,
      required String title,
      XtreamPlaylistItemType type = XtreamPlaylistItemType.movie,
      String? posterUrl,
      int? tmdbId,
      int? year,
      double? rating,
    }) {
      return XtreamPlaylistItem(
        accountId: account.id,
        categoryId: 'cat1',
        categoryName: 'Category',
        streamId: streamId,
        title: title,
        type: type,
        overview: null,
        posterUrl: posterUrl,
        rating: rating,
        releaseYear: year,
        tmdbId: tmdbId,
      );
    }

    test(
      'listAccounts mappe les comptes en ContentReference playlist',
      () async {
        final repo = _FakeIptvLocalRepository(accounts: [account]);
        final reader = IptvCatalogReader(repo);

        final refs = await reader.listAccounts();

        expect(refs.length, 1);
        expect(refs.first.id, account.id);
        expect(refs.first.title.display, account.alias);
        expect(refs.first.type, ContentType.playlist);
      },
    );

    test('listCategory retourne les items de la catégorie nettoyée', () async {
      final items = [
        _item(streamId: 1, title: 'Movie A', tmdbId: 100, year: 2020),
        _item(streamId: 2, title: 'Movie B', posterUrl: 'http://poster'),
      ];
      final playlists = [_playlist('cat1', 'Movies/Action', items)];

      final repo = _FakeIptvLocalRepository(
        accounts: [account],
        playlistsByAccount: {account.id: playlists},
      );
      final reader = IptvCatalogReader(repo);

      final key = CategoryKey(alias: 'Main', title: 'Action');

      final refs = await reader.listCategory(key);

      expect(refs.length, 2);
      expect(refs.first.id, '100'); // tmdbId prioritaire
      expect(refs.first.title, isA<MediaTitle>());
      expect(refs.first.title.display, 'Movie A');
      expect(refs.first.year, 2020);
    });

    test('searchCatalog filtre par titre et poster valide', () async {
      final items = [
        _item(streamId: 1, title: 'Good Movie', posterUrl: 'http://ok'),
        _item(streamId: 2, title: 'Bad Movie', posterUrl: ''), // pas de poster
      ];
      final playlists = [_playlist('cat1', 'Movies/Action', items)];

      final repo = _FakeIptvLocalRepository(
        accounts: [account],
        playlistsByAccount: {account.id: playlists},
      );
      final reader = IptvCatalogReader(repo);

      final refs = await reader.searchCatalog('good');

      expect(refs.length, 1);
      expect(refs.first.title.display, 'Good Movie');
      expect(refs.first.poster, isNotNull);
    });

    test('listCategoryLists construit des clés alias/cleanedTitle', () async {
      final items = [
        _item(streamId: 1, title: 'Movie A', posterUrl: 'http://ok'),
      ];
      final playlists = [_playlist('cat1', 'Movies/Action', items)];

      final repo = _FakeIptvLocalRepository(
        accounts: [account],
        playlistsByAccount: {account.id: playlists},
      );
      final reader = IptvCatalogReader(repo);

      final lists = await reader.listCategoryLists();

      expect(lists.length, 1);
      final key = lists.keys.single;
      expect(key, 'Main/Action');
      expect(lists[key]!.single.title.display, 'Movie A');
    });
  });
}
