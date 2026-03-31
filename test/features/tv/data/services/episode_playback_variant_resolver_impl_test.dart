import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/tv/data/services/episode_playback_variant_resolver_impl.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';

void main() {
  test(
    'resolves readable episode variants and converts global numbering',
    () async {
      final logger = _MemoryLogger();
      final urlBuilder = _FakeXtreamStreamUrlBuilder(
        urlsByKey: const <String, String?>{
          'xtream-a:101:2:8':
              'https://provider-a.example/series/101-s02e08.mkv',
          'stalker-b:201:2:8':
              'https://provider-b.example/series/201-s02e08.mkv',
        },
      );
      final resolver = EpisodePlaybackVariantResolverImpl(
        iptvLocal: _FakeIptvLocalRepository(
          accounts: <XtreamAccount>[
            XtreamAccount(
              id: 'xtream-a',
              alias: 'Salon',
              endpoint: XtreamEndpoint.parse('https://provider-a.example'),
              username: 'demo',
              status: XtreamAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
          ],
          stalkerAccounts: <StalkerAccount>[
            StalkerAccount(
              id: 'stalker-b',
              alias: 'Chambre',
              endpoint: StalkerEndpoint.parse('https://provider-b.example'),
              macAddress: '00:11:22:33:44:55',
              status: StalkerAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
          ],
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 101,
              title: 'One.Piece.1999.MULTI.1080p',
              type: XtreamPlaylistItemType.series,
              tmdbId: 37854,
            ),
            XtreamPlaylistItem(
              accountId: 'stalker-b',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 201,
              title: 'One.Piece.1999.VOSTFR.720p',
              type: XtreamPlaylistItemType.series,
              tmdbId: 37854,
            ),
          ],
        ),
        urlBuilder: urlBuilder,
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        seriesId: '37854',
        seasonNumber: 2,
        episodeNumber: 15,
        seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 1,
            episodeNumbers: const <int>[1, 2, 3, 4, 5, 6, 7],
          ),
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 2,
            episodeNumbers: const <int>[
              8,
              9,
              10,
              11,
              12,
              13,
              14,
              15,
              16,
              17,
              18,
              19,
              20,
            ],
          ),
        ],
        candidateSourceIds: const <String>{'xtream-a', 'stalker-b'},
      );

      expect(variants, hasLength(2));
      expect(variants.map((variant) => variant.sourceLabel), <String>[
        'Salon',
        'Chambre',
      ]);
      expect(variants.first.rawTitle, 'One.Piece.1999.MULTI.1080p');
      expect(variants.first.videoSource.episode, 15);
      expect(
        urlBuilder.requests.map((request) => request.episodeNumber).toSet(),
        <int>{8},
      );
    },
  );

  test(
    'filters candidate sources and ignores unreadable episode variants',
    () async {
      final logger = _MemoryLogger();
      final urlBuilder = _FakeXtreamStreamUrlBuilder(
        urlsByKey: const <String, String?>{
          'xtream-b:202:1:3': null,
          'stalker-b:303:1:3':
              'https://provider-b.example/series/303-s01e03.mkv',
        },
      );
      final resolver = EpisodePlaybackVariantResolverImpl(
        iptvLocal: _FakeIptvLocalRepository(
          accounts: <XtreamAccount>[
            XtreamAccount(
              id: 'xtream-a',
              alias: 'Salon',
              endpoint: XtreamEndpoint.parse('https://provider-a.example'),
              username: 'demo',
              status: XtreamAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
            XtreamAccount(
              id: 'xtream-b',
              alias: 'Bureau',
              endpoint: XtreamEndpoint.parse('https://provider-c.example'),
              username: 'demo',
              status: XtreamAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
          ],
          stalkerAccounts: <StalkerAccount>[
            StalkerAccount(
              id: 'stalker-b',
              alias: 'Chambre',
              endpoint: StalkerEndpoint.parse('https://provider-b.example'),
              macAddress: '00:11:22:33:44:55',
              status: StalkerAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
          ],
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 101,
              title: 'The.Last.of.Us.MULTI.1080p',
              type: XtreamPlaylistItemType.series,
              tmdbId: 100088,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-b',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 202,
              title: 'The.Last.of.Us.VOSTFR.720p',
              type: XtreamPlaylistItemType.series,
              tmdbId: 100088,
            ),
            XtreamPlaylistItem(
              accountId: 'stalker-b',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 303,
              title: 'The.Last.of.Us.TRUEFRENCH.1080p',
              type: XtreamPlaylistItemType.series,
              tmdbId: 100088,
            ),
          ],
        ),
        urlBuilder: urlBuilder,
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        seriesId: '100088',
        seasonNumber: 1,
        episodeNumber: 3,
        seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 1,
            episodeNumbers: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
        candidateSourceIds: const <String>{'xtream-b', 'stalker-b'},
      );

      expect(variants, hasLength(1));
      expect(variants.single.sourceLabel, 'Chambre');
      expect(urlBuilder.requests.map((request) => request.accountId), <String>[
        'xtream-b',
        'stalker-b',
      ]);
      expect(
        logger.events.where((event) => event.level == LogLevel.warn),
        hasLength(1),
      );
    },
  );

  test(
    'matches series items by xtream stream id for xtream detail pages',
    () async {
      final resolver = EpisodePlaybackVariantResolverImpl(
        iptvLocal: _FakeIptvLocalRepository(
          accounts: <XtreamAccount>[
            XtreamAccount(
              id: 'xtream-a',
              alias: 'Salon',
              endpoint: XtreamEndpoint.parse('https://provider-a.example'),
              username: 'demo',
              status: XtreamAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
            XtreamAccount(
              id: 'xtream-b',
              alias: 'Bureau',
              endpoint: XtreamEndpoint.parse('https://provider-b.example'),
              username: 'demo',
              status: XtreamAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
          ],
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 501,
              title: 'Andor.MULTI.1080p',
              type: XtreamPlaylistItemType.series,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-b',
              categoryId: 'series',
              categoryName: 'Series',
              streamId: 501,
              title: 'Andor.VOSTFR.2160p',
              type: XtreamPlaylistItemType.series,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByKey: const <String, String?>{
            'xtream-a:501:1:2':
                'https://provider-a.example/series/501-s01e02.mkv',
            'xtream-b:501:1:2':
                'https://provider-b.example/series/501-s01e02.mkv',
          },
        ),
        logger: _MemoryLogger(),
        diagnostics: PerformanceDiagnosticLogger(_MemoryLogger()),
      );

      final variants = await resolver.resolveVariants(
        seriesId: 'xtream:501',
        seasonNumber: 1,
        episodeNumber: 2,
        seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 1,
            episodeNumbers: const <int>[1, 2, 3, 4, 5, 6],
          ),
        ],
        candidateSourceIds: const <String>{'xtream-a', 'xtream-b'},
      );

      expect(variants, hasLength(2));
      expect(variants.map((variant) => variant.id), <String>[
        'xtream-a:501',
        'xtream-b:501',
      ]);
    },
  );
}

class _FakeIptvLocalRepository implements IptvLocalRepository {
  _FakeIptvLocalRepository({
    this.accounts = const <XtreamAccount>[],
    this.stalkerAccounts = const <StalkerAccount>[],
    this.items = const <XtreamPlaylistItem>[],
  });

  final List<XtreamAccount> accounts;
  final List<StalkerAccount> stalkerAccounts;
  final List<XtreamPlaylistItem> items;

  @override
  Future<List<XtreamAccount>> getAccounts() async => accounts;

  @override
  Future<List<StalkerAccount>> getStalkerAccounts() async => stalkerAccounts;

  @override
  Future<List<XtreamPlaylistItem>> getAllPlaylistItems({
    Set<String>? accountIds,
    XtreamPlaylistItemType? type,
  }) async {
    return items
        .where((item) {
          final matchesAccount =
              accountIds == null || accountIds.contains(item.accountId);
          final matchesType = type == null || type == item.type;
          return matchesAccount && matchesType;
        })
        .toList(growable: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _FakeXtreamStreamUrlBuilder implements XtreamStreamUrlBuilder {
  _FakeXtreamStreamUrlBuilder({required this.urlsByKey});

  final Map<String, String?> urlsByKey;
  final List<_SeriesStreamRequest> requests = <_SeriesStreamRequest>[];

  @override
  Future<String?> buildStreamUrlFromSeriesItem({
    required XtreamPlaylistItem item,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    requests.add(
      _SeriesStreamRequest(
        accountId: item.accountId,
        streamId: item.streamId,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      ),
    );
    return urlsByKey['${item.accountId}:${item.streamId}:$seasonNumber:$episodeNumber'];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _SeriesStreamRequest {
  const _SeriesStreamRequest({
    required this.accountId,
    required this.streamId,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  final String accountId;
  final int streamId;
  final int seasonNumber;
  final int episodeNumber;
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
