import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart';
import 'package:movi/src/features/movie/domain/services/movie_variant_matcher.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test(
    'resolves readable movie variants and normalizes lightweight metadata',
    () async {
      final logger = _MemoryLogger();
      final resolver = MoviePlaybackVariantResolverImpl(
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
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 101,
              title: 'The.Matrix.1999.TRUEFRENCH.1080p.BluRay.x264',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 603,
            ),
            XtreamPlaylistItem(
              accountId: 'stalker-b',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 102,
              title: 'The.Matrix.1999.VOSTFR.720p.WEBRip',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 603,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 103,
              title: 'The.Matrix.1999.CAM',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 603,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            101: 'https://provider-a.example/movie/101.mp4',
            102: 'https://provider-b.example/movie/102.mkv',
            103: null,
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        movieId: '603',
        title: 'The Matrix',
        candidateSourceIds: const <String>{'xtream-a', 'stalker-b'},
      );

      expect(variants, hasLength(2));
      expect(variants.first.sourceLabel, 'Salon');
      expect(variants.first.normalizedTitle, 'The Matrix');
      expect(variants.first.qualityLabel, 'Full HD');
      expect(variants.first.audioLanguageCode, 'fr');
      expect(variants[1].sourceLabel, 'Chambre');
      expect(variants[1].subtitleLanguageCode, 'fr');
      expect(variants[1].hasSubtitles, isTrue);
      expect(
        logger.events.where((event) => event.level == LogLevel.warn),
        hasLength(1),
      );
    },
  );

  test(
    'extracts dynamic range labels such as HDR10 from movie titles',
    () async {
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 201,
              title: 'Dune.2021.VOSTFR.2160p.HDR10.WEBRip',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 438631,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            201: 'https://provider-a.example/movie/201.mkv',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: _MemoryLogger(),
        diagnostics: PerformanceDiagnosticLogger(_MemoryLogger()),
      );

      final variants = await resolver.resolveVariants(
        movieId: '438631',
        title: 'Dune',
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, hasLength(1));
      expect(variants.single.qualityLabel, '4K');
      expect(variants.single.dynamicRangeLabel, 'HDR10');
      expect(variants.single.audioLanguageLabel, 'VO');
      expect(variants.single.subtitleLanguageLabel, 'FR');
    },
  );

  test(
    'extracts metadata from short raw title markers such as pipes and FHD',
    () async {
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 301,
              title: 'Dune.Part.Two.2024.|FR|.|FHD|',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 693134,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 302,
              title: 'Dune.Part.Two.2024.|VOST|.UHD.HDR10',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 693134,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            301: 'https://provider-a.example/movie/301.mkv',
            302: 'https://provider-a.example/movie/302.mkv',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: _MemoryLogger(),
        diagnostics: PerformanceDiagnosticLogger(_MemoryLogger()),
      );

      final variants = await resolver.resolveVariants(
        movieId: '693134',
        title: 'Dune Part Two',
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, hasLength(2));
      expect(variants.first.audioLanguageCode, 'fr');
      expect(variants.first.audioLanguageLabel, 'FR');
      expect(variants.first.qualityLabel, 'Full HD');
      expect(variants.first.qualityRank, 3);
      expect(variants[1].audioLanguageLabel, 'VO');
      expect(variants[1].hasSubtitles, isTrue);
      expect(variants[1].qualityLabel, '4K');
      expect(variants[1].dynamicRangeLabel, 'HDR10');
    },
  );

  test(
    'keeps visible language metadata even when normalizedTitle strips short markers',
    () async {
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 401,
              title: 'Blade.Runner.1982.|VOSTFR|.HD',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 78,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            401: 'https://provider-a.example/movie/401.mkv',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: _MemoryLogger(),
        diagnostics: PerformanceDiagnosticLogger(_MemoryLogger()),
      );

      final variants = await resolver.resolveVariants(
        movieId: '78',
        title: 'Blade Runner',
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, hasLength(1));
      expect(variants.single.normalizedTitle, 'Blade Runner 1982');
      expect(variants.single.audioLanguageLabel, 'VO');
      expect(variants.single.subtitleLanguageLabel, 'FR');
      expect(variants.single.qualityLabel, 'HD');
    },
  );

  test(
    'feeds detected quality ranks into playback selection ranking',
    () async {
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 501,
              title: 'Dune.Part.Two.2024.|FR|.|FHD|',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 693134,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 502,
              title: 'Dune.Part.Two.2024.|VOST|.UHD',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 693134,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            501: 'https://provider-a.example/movie/501.mkv',
            502: 'https://provider-a.example/movie/502.mkv',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: _MemoryLogger(),
        diagnostics: PerformanceDiagnosticLogger(_MemoryLogger()),
      );

      final variants = await resolver.resolveVariants(
        movieId: '693134',
        title: 'Dune Part Two',
        candidateSourceIds: const <String>{'xtream-a'},
      );
      final decision = const PlaybackSelectionService().select(
        variants: variants,
        preferences: const PlaybackSelectionPreferences(
          preferredQualityRank: 4,
        ),
        context: const PlaybackSelectionContext(contentType: ContentType.movie),
      );

      expect(decision.disposition, PlaybackSelectionDisposition.manualSelection);
      expect(decision.reason, PlaybackSelectionReason.ambiguousVariants);
      expect(decision.selectedVariant, isNull);
      expect(decision.rankedVariants.first.qualityLabel, '4K');
      expect(decision.rankedVariants.first.qualityRank, 4);
    },
  );

  test(
    'groups movie variants by cleaned title and year for an xtream detail page',
    () async {
      final logger = _MemoryLogger();
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 501,
              title: 'Dune.2021.TRUEFRENCH.1080p.BluRay.x264',
              type: XtreamPlaylistItemType.movie,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 502,
              title: 'Dune.2021.VOSTFR.2160p.WEBRip',
              type: XtreamPlaylistItemType.movie,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 503,
              title: 'Dune.2024.TRUEFRENCH.2160p.WEBRip',
              type: XtreamPlaylistItemType.movie,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            501: 'https://provider-a.example/movie/501.mp4',
            502: 'https://provider-a.example/movie/502.mp4',
            503: 'https://provider-a.example/movie/503.mp4',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        movieId: 'xtream:501',
        title: 'Dune',
        releaseYear: 2021,
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, hasLength(2));
      expect(variants.map((variant) => variant.id), <String>[
        'xtream-a:501',
        'xtream-a:502',
      ]);
      expect(
        logger.events.where(
          (event) =>
              event.level == LogLevel.warn &&
              event.message.contains('Ignoring weak movie variant match'),
        ),
        hasLength(1),
      );
    },
  );

  test(
    'keeps tmdb strict matches and adds compatible title-year variants',
    () async {
      final logger = _MemoryLogger();
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 601,
              title: 'The.Matrix.1999.TRUEFRENCH.1080p',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 603,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 602,
              title: 'The.Matrix.1999.VOSTFR.2160p',
              type: XtreamPlaylistItemType.movie,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            601: 'https://provider-a.example/movie/601.mp4',
            602: 'https://provider-a.example/movie/602.mp4',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        movieId: '603',
        title: 'The Matrix',
        releaseYear: 1999,
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, hasLength(2));
      expect(variants.map((variant) => variant.id), <String>[
        'xtream-a:601',
        'xtream-a:602',
      ]);
      expect(
        logger.events.where((event) => event.level == LogLevel.warn),
        isEmpty,
      );
    },
  );

  test(
    'groups coherent title-only variants across multiple sources when tmdb is absent',
    () async {
      final logger = _MemoryLogger();
      final resolver = MoviePlaybackVariantResolverImpl(
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
              alias: 'Chambre',
              endpoint: XtreamEndpoint.parse('https://provider-b.example'),
              username: 'demo',
              status: XtreamAccountStatus.active,
              createdAt: DateTime(2026, 3, 30),
            ),
          ],
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 701,
              title: 'Blade.Runner.1982.TRUEFRENCH.1080p',
              type: XtreamPlaylistItemType.movie,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-b',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 702,
              title: 'Blade.Runner.1982.VOSTFR.2160p',
              type: XtreamPlaylistItemType.movie,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            701: 'https://provider-a.example/movie/701.mp4',
            702: 'https://provider-b.example/movie/702.mp4',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        movieId: 'xtream:701',
        title: 'Blade Runner',
        releaseYear: 1982,
        candidateSourceIds: const <String>{'xtream-a', 'xtream-b'},
      );

      expect(variants, hasLength(2));
      expect(variants.map((variant) => variant.sourceLabel), <String>[
        'Salon',
        'Chambre',
      ]);
      expect(
        logger.events.where((event) => event.level == LogLevel.warn),
        isEmpty,
      );
    },
  );

  test(
    'returns a single variant when only one readable movie matches',
    () async {
      final logger = _MemoryLogger();
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 801,
              title: 'Arrival.2016.TRUEFRENCH.1080p',
              type: XtreamPlaylistItemType.movie,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            801: 'https://provider-a.example/movie/801.mp4',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        movieId: 'xtream:801',
        title: 'Arrival',
        releaseYear: 2016,
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, hasLength(1));
      expect(variants.single.id, 'xtream-a:801');
    },
  );

  test(
    'does not log weak tmdb conflicts for unrelated titles on a tmdb detail page',
    () async {
      final logger = _MemoryLogger();
      final resolver = MoviePlaybackVariantResolverImpl(
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
          items: const <XtreamPlaylistItem>[
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 901,
              title: 'Completely.Different.Movie.2020.TRUEFRENCH.1080p',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 111111,
            ),
            XtreamPlaylistItem(
              accountId: 'xtream-a',
              categoryId: 'movies',
              categoryName: 'Movies',
              streamId: 902,
              title: 'Another.Unrelated.Film.2021.VOSTFR.2160p',
              type: XtreamPlaylistItemType.movie,
              tmdbId: 222222,
            ),
          ],
        ),
        urlBuilder: _FakeXtreamStreamUrlBuilder(
          urlsByStreamId: const <int, String?>{
            901: 'https://provider-a.example/movie/901.mp4',
            902: 'https://provider-a.example/movie/902.mp4',
          },
        ),
        matcher: const MovieVariantMatcher(),
        logger: logger,
        diagnostics: PerformanceDiagnosticLogger(logger),
      );

      final variants = await resolver.resolveVariants(
        movieId: '603',
        title: 'The Matrix',
        releaseYear: 1999,
        candidateSourceIds: const <String>{'xtream-a'},
      );

      expect(variants, isEmpty);
      expect(
        logger.events.where(
          (event) =>
              event.level == LogLevel.warn &&
              event.message.contains('Ignoring weak movie variant match'),
        ),
        isEmpty,
      );
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
  const _FakeXtreamStreamUrlBuilder({required this.urlsByStreamId});

  final Map<int, String?> urlsByStreamId;

  @override
  Future<String?> buildStreamUrlFromMovieItem(XtreamPlaylistItem item) async {
    return urlsByStreamId[item.streamId];
  }

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
