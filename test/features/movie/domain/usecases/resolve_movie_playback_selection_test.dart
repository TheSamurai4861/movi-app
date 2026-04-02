import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/domain/services/movie_playback_variant_resolver.dart';
import 'package:movi/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('applies resume position before selecting the movie variant', () async {
    final logger = _MemoryLogger();
    final usecase = ResolveMoviePlaybackSelection(
      _FakeMoviePlaybackVariantResolver(
        variants: <PlaybackVariant>[
          PlaybackVariant(
            id: 'xtream-a:101',
            sourceId: 'xtream-a',
            sourceLabel: 'Salon',
            videoSource: const VideoSource(
              url: 'https://provider.example/movie/101.mp4',
              title: 'The Matrix',
              contentId: '603',
              contentType: ContentType.movie,
            ),
            contentType: ContentType.movie,
            rawTitle: 'The.Matrix.1999.1080p',
            normalizedTitle: 'The Matrix',
            qualityLabel: 'Full HD',
            qualityRank: 3,
          ),
        ],
      ),
      const PlaybackSelectionService(),
      _FakePlaybackHistoryRepository(
        entry: const PlaybackHistoryEntry(
          contentId: '603',
          type: ContentType.movie,
          title: 'The Matrix',
          lastPosition: Duration(minutes: 12),
          duration: Duration(minutes: 120),
        ),
      ),
      logger,
      PerformanceDiagnosticLogger(logger),
    );

    final decision = await usecase(
      movieId: '603',
      title: 'The Matrix',
      releaseYear: 1999,
      userId: 'user-a',
      candidateSourceIds: const <String>{'xtream-a'},
      preferences: const PlaybackSelectionPreferences(
        preferredSourceIds: <String>{'xtream-a'},
      ),
      context: const PlaybackSelectionContext(contentType: ContentType.movie),
    );

    expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
    expect(
      decision.selectedVariant?.videoSource.resumePosition,
      const Duration(minutes: 12),
    );
  });

  test(
    'rejects resume position when progress is below in-progress threshold',
    () async {
      final logger = _MemoryLogger();
      final usecase = ResolveMoviePlaybackSelection(
        _FakeMoviePlaybackVariantResolver(
          variants: <PlaybackVariant>[
            PlaybackVariant(
              id: 'xtream-a:101',
              sourceId: 'xtream-a',
              sourceLabel: 'Salon',
              videoSource: const VideoSource(
                url: 'https://provider.example/movie/101.mp4',
                title: 'The Matrix',
                contentId: '603',
                contentType: ContentType.movie,
              ),
              contentType: ContentType.movie,
              rawTitle: 'The.Matrix.1999.1080p',
              normalizedTitle: 'The Matrix',
              qualityLabel: 'Full HD',
              qualityRank: 3,
            ),
          ],
        ),
        const PlaybackSelectionService(),
        _FakePlaybackHistoryRepository(
          entry: const PlaybackHistoryEntry(
            contentId: '603',
            type: ContentType.movie,
            title: 'The Matrix',
            lastPosition: Duration(seconds: 8),
            duration: Duration(minutes: 120),
          ),
        ),
        logger,
        PerformanceDiagnosticLogger(logger),
      );

      final decision = await usecase(
        movieId: '603',
        title: 'The Matrix',
        releaseYear: 1999,
        userId: 'user-a',
        candidateSourceIds: const <String>{'xtream-a'},
        preferences: const PlaybackSelectionPreferences(
          preferredSourceIds: <String>{'xtream-a'},
        ),
        context: const PlaybackSelectionContext(contentType: ContentType.movie),
      );

      expect(decision.disposition, PlaybackSelectionDisposition.autoPlay);
      expect(decision.selectedVariant?.videoSource.resumePosition, isNull);
    },
  );

  test('rejects resume position when duration is invalid', () async {
    final logger = _MemoryLogger();
    final usecase = ResolveMoviePlaybackSelection(
      _FakeMoviePlaybackVariantResolver(variants: _defaultVariants()),
      const PlaybackSelectionService(),
      _FakePlaybackHistoryRepository(
        entry: const PlaybackHistoryEntry(
          contentId: '603',
          type: ContentType.movie,
          title: 'The Matrix',
          lastPosition: Duration(minutes: 20),
          duration: Duration.zero,
        ),
      ),
      logger,
      PerformanceDiagnosticLogger(logger),
    );

    final decision = await _resolveDefault(usecase);
    expect(decision.selectedVariant?.videoSource.resumePosition, isNull);
  });

  test('rejects resume position when position is null', () async {
    final logger = _MemoryLogger();
    final usecase = ResolveMoviePlaybackSelection(
      _FakeMoviePlaybackVariantResolver(variants: _defaultVariants()),
      const PlaybackSelectionService(),
      _FakePlaybackHistoryRepository(
        entry: const PlaybackHistoryEntry(
          contentId: '603',
          type: ContentType.movie,
          title: 'The Matrix',
          duration: Duration(minutes: 120),
        ),
      ),
      logger,
      PerformanceDiagnosticLogger(logger),
    );

    final decision = await _resolveDefault(usecase);
    expect(decision.selectedVariant?.videoSource.resumePosition, isNull);
  });

  test(
    'rejects resume position when progress is above max threshold',
    () async {
      final logger = _MemoryLogger();
      final usecase = ResolveMoviePlaybackSelection(
        _FakeMoviePlaybackVariantResolver(variants: _defaultVariants()),
        const PlaybackSelectionService(),
        _FakePlaybackHistoryRepository(
          entry: const PlaybackHistoryEntry(
            contentId: '603',
            type: ContentType.movie,
            title: 'The Matrix',
            lastPosition: Duration(minutes: 115),
            duration: Duration(minutes: 120),
          ),
        ),
        logger,
        PerformanceDiagnosticLogger(logger),
      );

      final decision = await _resolveDefault(usecase);
      expect(decision.selectedVariant?.videoSource.resumePosition, isNull);
    },
  );
}

Future<PlaybackSelectionDecision> _resolveDefault(
  ResolveMoviePlaybackSelection usecase,
) {
  return usecase(
    movieId: '603',
    title: 'The Matrix',
    releaseYear: 1999,
    userId: 'user-a',
    candidateSourceIds: const <String>{'xtream-a'},
    preferences: const PlaybackSelectionPreferences(
      preferredSourceIds: <String>{'xtream-a'},
    ),
    context: const PlaybackSelectionContext(contentType: ContentType.movie),
  );
}

List<PlaybackVariant> _defaultVariants() {
  return <PlaybackVariant>[
    PlaybackVariant(
      id: 'xtream-a:101',
      sourceId: 'xtream-a',
      sourceLabel: 'Salon',
      videoSource: const VideoSource(
        url: 'https://provider.example/movie/101.mp4',
        title: 'The Matrix',
        contentId: '603',
        contentType: ContentType.movie,
      ),
      contentType: ContentType.movie,
      rawTitle: 'The.Matrix.1999.1080p',
      normalizedTitle: 'The Matrix',
      qualityLabel: 'Full HD',
      qualityRank: 3,
    ),
  ];
}

class _FakeMoviePlaybackVariantResolver
    implements MoviePlaybackVariantResolver {
  const _FakeMoviePlaybackVariantResolver({required this.variants});

  final List<PlaybackVariant> variants;

  @override
  Future<List<PlaybackVariant>> resolveVariants({
    required String movieId,
    required String title,
    int? releaseYear,
    Uri? poster,
    Set<String>? candidateSourceIds,
  }) async {
    return variants;
  }
}

class _FakePlaybackHistoryRepository implements PlaybackHistoryRepository {
  const _FakePlaybackHistoryRepository({this.entry});

  final PlaybackHistoryEntry? entry;

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _MemoryLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void warn(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}
}
