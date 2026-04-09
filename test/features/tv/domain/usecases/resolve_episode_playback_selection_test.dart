import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';
import 'package:movi/src/features/tv/domain/services/episode_playback_variant_resolver.dart';
import 'package:movi/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  setUp(() {
    _FakePlaybackHistoryRepository.getEntryCalls = 0;
    _FakePlaybackHistoryRepository.getSeriesResumeStateCalls = 0;
  });

  test(
    'applies resume position before selecting the episode variant',
    () async {
      final logger = _MemoryLogger();
      final resolver = _FakeEpisodePlaybackVariantResolver(
        variants: <PlaybackVariant>[
          PlaybackVariant(
            id: 'xtream-a:101',
            sourceId: 'xtream-a',
            sourceLabel: 'Salon',
            videoSource: const VideoSource(
              url: 'https://provider.example/series/101-s02e15.mkv',
              title: 'One Piece',
              contentId: '37854',
              contentType: ContentType.series,
              season: 2,
              episode: 15,
            ),
            contentType: ContentType.series,
            rawTitle: 'One.Piece.1999.MULTI.1080p',
            normalizedTitle: 'One Piece',
          ),
        ],
      );
      final usecase = ResolveEpisodePlaybackSelection(
        resolver,
        const PlaybackSelectionService(),
        _FakePlaybackHistoryRepository(
          entry: const PlaybackHistoryEntry(
            contentId: '37854',
            type: ContentType.series,
            title: 'One Piece',
            lastPosition: Duration(minutes: 7),
            duration: Duration(minutes: 24),
            season: 2,
            episode: 15,
          ),
        ),
        logger,
        PerformanceDiagnosticLogger(logger),
      );

      final decision = await usecase(
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
            episodeNumbers: const <int>[8, 9, 10, 11, 12, 13, 14, 15],
          ),
        ],
        userId: 'user-a',
        candidateSourceIds: const <String>{'xtream-a'},
        preferences: const PlaybackSelectionPreferences(
          preferredSourceIds: <String>{'xtream-a'},
        ),
        context: const PlaybackSelectionContext(
          contentType: ContentType.series,
        ),
      );

      expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
      expect(
        decision.selectedVariant?.videoSource.resumePosition,
        const Duration(minutes: 7),
      );
      expect(decision.launchPlan, isNotNull);
      expect(decision.launchPlan?.contentType, ContentType.series);
      expect(decision.launchPlan?.targetContentId, '37854');
      expect(decision.launchPlan?.season, 2);
      expect(decision.launchPlan?.episode, 15);
      expect(decision.launchPlan?.resumePosition, const Duration(minutes: 7));
      expect(decision.resumeEligible, isTrue);
      expect(decision.resumeReasonCode, ResumeReasonCode.applied);
      expect(_FakePlaybackHistoryRepository.getSeriesResumeStateCalls, 1);
      expect(_FakePlaybackHistoryRepository.getEntryCalls, 0);
      expect(resolver.lastCall?.seriesId, '37854');
      expect(resolver.lastCall?.seasonNumber, 2);
      expect(resolver.lastCall?.episodeNumber, 15);
      expect(resolver.lastCall?.candidateSourceIds, const <String>{'xtream-a'});
      expect(
        logger.messages.any(
          (message) =>
              message.contains('op=episode_resume_resolution') &&
              message.contains('event=resume_eligible') &&
              message.contains('contentType=series') &&
              message.contains('seasonNumber=2') &&
              message.contains('episodeNumber=15') &&
              message.contains('reasonCode=applied'),
        ),
        isTrue,
      );
      expect(
        logger.messages.any(
          (message) =>
              message.contains('op=episode_playback_selection') &&
              message.contains('result=autoPlay') &&
              message.contains('resumeRequested=true') &&
              message.contains('resumeApplied=true') &&
              message.contains('resumeReasonCode=applied'),
        ),
        isTrue,
      );
    },
  );

  test('returns manual selection for ambiguous episode variants', () async {
    final usecase = ResolveEpisodePlaybackSelection(
      _FakeEpisodePlaybackVariantResolver(
        variants: <PlaybackVariant>[
          PlaybackVariant(
            id: 'xtream-a:101',
            sourceId: 'xtream-a',
            sourceLabel: 'Salon',
            videoSource: const VideoSource(
              url: 'https://provider.example/series/101-s01e03.mkv',
              contentId: '100088',
              contentType: ContentType.series,
              season: 1,
              episode: 3,
            ),
            contentType: ContentType.series,
            rawTitle: 'The.Last.of.Us.MULTI.1080p',
            normalizedTitle: 'The Last of Us',
          ),
          PlaybackVariant(
            id: 'xtream-b:202',
            sourceId: 'xtream-b',
            sourceLabel: 'Bureau',
            videoSource: const VideoSource(
              url: 'https://provider.example/series/202-s01e03.mkv',
              contentId: '100088',
              contentType: ContentType.series,
              season: 1,
              episode: 3,
            ),
            contentType: ContentType.series,
            rawTitle: 'The.Last.of.Us.VOSTFR.1080p',
            normalizedTitle: 'The Last of Us',
          ),
        ],
      ),
      const PlaybackSelectionService(),
      const _FakePlaybackHistoryRepository(),
      _MemoryLogger(),
      PerformanceDiagnosticLogger(_MemoryLogger()),
    );

    final decision = await usecase(
      seriesId: '100088',
      seasonNumber: 1,
      episodeNumber: 3,
      seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
        EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
          seasonNumber: 1,
          episodeNumbers: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
        ),
      ],
      preferences: const PlaybackSelectionPreferences(),
      context: const PlaybackSelectionContext(contentType: ContentType.series),
    );

    expect(decision.disposition, PlaybackSelectionDisposition.manualSelection);
    expect(decision.selectedVariant, isNull);
    expect(decision.rankedVariants, hasLength(2));
  });

  test(
    'rejects resume position when progress is below in-progress threshold',
    () async {
      final logger = _MemoryLogger();
      final usecase = ResolveEpisodePlaybackSelection(
        _FakeEpisodePlaybackVariantResolver(
          variants: <PlaybackVariant>[
            PlaybackVariant(
              id: 'xtream-a:101',
              sourceId: 'xtream-a',
              sourceLabel: 'Salon',
              videoSource: const VideoSource(
                url: 'https://provider.example/series/101-s01e03.mkv',
                contentId: '100088',
                contentType: ContentType.series,
                season: 1,
                episode: 3,
              ),
              contentType: ContentType.series,
              rawTitle: 'The.Last.of.Us.MULTI.1080p',
              normalizedTitle: 'The Last of Us',
            ),
          ],
        ),
        const PlaybackSelectionService(),
        _FakePlaybackHistoryRepository(
          entry: const PlaybackHistoryEntry(
            contentId: '100088',
            type: ContentType.series,
            title: 'The Last of Us',
            lastPosition: Duration(seconds: 8),
            duration: Duration(minutes: 52),
            season: 1,
            episode: 3,
          ),
        ),
        logger,
        PerformanceDiagnosticLogger(logger),
      );

      final decision = await usecase(
        seriesId: '100088',
        seasonNumber: 1,
        episodeNumber: 3,
        seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
          EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: 1,
            episodeNumbers: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9],
          ),
        ],
        preferences: const PlaybackSelectionPreferences(
          preferredSourceIds: <String>{'xtream-a'},
        ),
        context: const PlaybackSelectionContext(
          contentType: ContentType.series,
        ),
      );

      expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
      expect(decision.selectedVariant?.videoSource.resumePosition, isNull);
      expect(decision.launchPlan?.targetContentId, '100088');
      expect(decision.launchPlan?.season, 1);
      expect(decision.launchPlan?.episode, 3);
      expect(decision.launchPlan?.resumePosition, isNull);
      expect(decision.resumeEligible, isFalse);
      expect(decision.resumeReasonCode, ResumeReasonCode.progressOutOfRange);
    },
  );

  test('returns unavailable when no playable episode variant exists', () async {
    final usecase = ResolveEpisodePlaybackSelection(
      _FakeEpisodePlaybackVariantResolver(variants: const <PlaybackVariant>[]),
      const PlaybackSelectionService(),
      const _FakePlaybackHistoryRepository(),
      _MemoryLogger(),
      PerformanceDiagnosticLogger(_MemoryLogger()),
    );

    final decision = await usecase(
      seriesId: '99999',
      seasonNumber: 1,
      episodeNumber: 1,
      seasonSnapshots: <EpisodePlaybackSeasonSnapshot>[
        EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
          seasonNumber: 1,
          episodeNumbers: const <int>[1],
        ),
      ],
      preferences: const PlaybackSelectionPreferences(),
      context: const PlaybackSelectionContext(contentType: ContentType.series),
    );

    expect(decision.disposition, PlaybackSelectionDisposition.unavailable);
    expect(decision.reason, PlaybackSelectionReason.noPlayableVariant);
    expect(decision.rankedVariants, isEmpty);
  });
}

class _FakeEpisodePlaybackVariantResolver
    implements EpisodePlaybackVariantResolver {
  _FakeEpisodePlaybackVariantResolver({required this.variants});

  final List<PlaybackVariant> variants;
  _ResolverCall? lastCall;

  @override
  Future<List<PlaybackVariant>> resolveVariants({
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required List<EpisodePlaybackSeasonSnapshot> seasonSnapshots,
    Set<String>? candidateSourceIds,
  }) async {
    lastCall = _ResolverCall(
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      seasonSnapshots: seasonSnapshots,
      candidateSourceIds: candidateSourceIds,
    );
    return variants;
  }
}

class _ResolverCall {
  const _ResolverCall({
    required this.seriesId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.seasonSnapshots,
    required this.candidateSourceIds,
  });

  final String seriesId;
  final int seasonNumber;
  final int episodeNumber;
  final List<EpisodePlaybackSeasonSnapshot> seasonSnapshots;
  final Set<String>? candidateSourceIds;
}

class _FakePlaybackHistoryRepository implements PlaybackHistoryRepository {
  const _FakePlaybackHistoryRepository({this.entry});

  final PlaybackHistoryEntry? entry;
  static int getEntryCalls = 0;
  static int getSeriesResumeStateCalls = 0;

  @override
  Future<PlaybackHistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String? userId,
  }) async {
    getSeriesResumeStateCalls += 1;
    return entry;
  }

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    getEntryCalls += 1;
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _MemoryLogger implements AppLogger {
  final List<String> messages = <String>[];

  @override
  void debug(String message, {String? category}) {
    messages.add(message);
  }

  @override
  void info(String message, {String? category}) {
    messages.add(message);
  }

  @override
  void warn(String message, {String? category}) {
    messages.add(message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    messages.add(message);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }
}
