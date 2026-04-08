import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/features/iptv/application/services/iptv_playlist_analysis_service.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

void main() {
  test(
    'searchCatalog returns normalized and degraded-safe content references',
    () async {
      final logger = _MemoryLogger();
      final reader = IptvCatalogReader(
        _FakeIptvLocalRepository(
          searchItemsResult: <XtreamPlaylistItem>[
            const XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 100,
              title: 'The.Matrix.1999.MULTi.TRUEFRENCH.1080p.BluRay.x264',
              type: XtreamPlaylistItemType.movie,
              overview: null,
              posterUrl: null,
              containerExtension: 'mkv',
              rating: null,
              releaseYear: null,
              tmdbId: null,
            ),
            const XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 0,
              title: '---',
              type: XtreamPlaylistItemType.movie,
              overview: null,
              posterUrl: null,
              containerExtension: null,
              rating: null,
              releaseYear: 3024,
              tmdbId: null,
            ),
          ],
        ),
        const IptvPlaylistAnalysisService(),
        logger,
      );

      final results = await reader.searchCatalog('matrix');

      expect(results, hasLength(1));
      expect(results.single.id, 'xtream:100');
      expect(results.single.title.value, 'The Matrix');
      expect(results.single.poster, isNull);
      expect(results.single.year, 1999);
      expect(results.single.rating, isNull);
      expect(logger.events, hasLength(1));
      expect(logger.events.single.level, LogLevel.warn);
      expect(
        logger.events.single.message,
        contains('Skipping unsupported IPTV item'),
      );
    },
  );

  test(
    'listCategory filters unsupported items without breaking valid entries',
    () async {
      final now = DateTime(2026, 3, 30);
      final logger = _MemoryLogger();
      final account = XtreamAccount(
        id: 'xtream-a',
        alias: 'Salon',
        endpoint: XtreamEndpoint.parse('https://provider.example'),
        username: 'demo',
        status: XtreamAccountStatus.active,
        createdAt: now,
      );
      final playlist = const XtreamPlaylist(
        id: 'xtream-a_movies_10',
        accountId: 'xtream-a',
        title: 'Movies',
        type: XtreamPlaylistType.movies,
        items: <XtreamPlaylistItem>[],
      );

      final reader = IptvCatalogReader(
        _FakeIptvLocalRepository(
          accounts: <XtreamAccount>[account],
          playlistsByAccount: <String, List<XtreamPlaylist>>{
            'xtream-a': <XtreamPlaylist>[playlist],
          },
          playlistItemsByPlaylistId: <String, List<XtreamPlaylistItem>>{
            'xtream-a_movies_10': const <XtreamPlaylistItem>[
              XtreamPlaylistItem(
                accountId: 'xtream-a',
                categoryId: '10',
                categoryName: 'Movies',
                streamId: 200,
                title: 'Inception',
                type: XtreamPlaylistItemType.movie,
                overview: null,
                posterUrl:
                    'https://cdn.example.test/posters/inception-provider.jpg',
                containerExtension: 'mp4',
                rating: 8.1,
                releaseYear: 2010,
                tmdbId: null,
              ),
              XtreamPlaylistItem(
                accountId: 'xtream-a',
                categoryId: '',
                categoryName: 'Movies',
                streamId: 0,
                title: '---',
                type: XtreamPlaylistItemType.movie,
                overview: null,
                posterUrl: null,
                containerExtension: null,
                rating: null,
                releaseYear: null,
                tmdbId: null,
              ),
            ],
          },
        ),
        const IptvPlaylistAnalysisService(),
        logger,
      );

      final results = await reader.listCategory(
        const CategoryKey(alias: 'Salon', title: 'Movies'),
      );

      expect(results, hasLength(1));
      expect(results.single.title.value, 'Inception');
      expect(results.single.poster, isNotNull);
      expect(results.single.year, 2010);
      expect(results.single.rating, 8.1);
      expect(logger.events, hasLength(1));
    },
  );
}

class _FakeIptvLocalRepository implements IptvLocalRepository {
  _FakeIptvLocalRepository({
    this.accounts = const <XtreamAccount>[],
    this.playlistsByAccount = const <String, List<XtreamPlaylist>>{},
    this.playlistItemsByPlaylistId = const <String, List<XtreamPlaylistItem>>{},
    this.searchItemsResult = const <XtreamPlaylistItem>[],
  });

  final List<XtreamAccount> accounts;
  final Map<String, List<XtreamPlaylist>> playlistsByAccount;
  final Map<String, List<XtreamPlaylistItem>> playlistItemsByPlaylistId;
  final List<XtreamPlaylistItem> searchItemsResult;

  @override
  Future<List<XtreamAccount>> getAccounts({
    bool includeAllOwners = false,
  }) async => accounts;

  @override
  Future<List<StalkerAccount>> getStalkerAccounts({
    bool includeAllOwners = false,
  }) async =>
      const <StalkerAccount>[];

  @override
  Future<List<XtreamPlaylist>> getPlaylists(
    String accountId, {
    int? itemLimit,
  }) async {
    return playlistsByAccount[accountId] ?? const <XtreamPlaylist>[];
  }

  @override
  Future<List<XtreamPlaylistItem>> getPlaylistItems({
    required String accountId,
    required String playlistId,
    required String categoryName,
    required XtreamPlaylistType playlistType,
    int? limit,
    int? offset,
  }) async {
    final items =
        playlistItemsByPlaylistId[playlistId] ?? const <XtreamPlaylistItem>[];
    if (limit == null || limit >= items.length) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  @override
  Future<List<XtreamPlaylistSettings>> getPlaylistSettings(
    String accountId,
  ) async => const <XtreamPlaylistSettings>[];

  @override
  Future<List<XtreamPlaylistItem>> searchItems(
    String query, {
    int limit = 500,
    Set<String>? accountIds,
  }) async {
    return searchItemsResult.take(limit).toList(growable: false);
  }

  @override
  Future<Set<int>> getAvailableTmdbIds({
    XtreamPlaylistItemType? type,
    Set<String>? accountIds,
  }) async => <int>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _MemoryLogger implements AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void debug(String message, {String? category}) {
    log(LogLevel.debug, message, category: category);
  }

  @override
  void info(String message, {String? category}) {
    log(LogLevel.info, message, category: category);
  }

  @override
  void warn(String message, {String? category}) {
    log(LogLevel.warn, message, category: category);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime(2026, 3, 30),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
