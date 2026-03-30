import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/domain/services/movie_playback_variant_resolver.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class ResolveMoviePlaybackSelection {
  const ResolveMoviePlaybackSelection(
    this._resolver,
    this._selectionService,
    this._history,
    this._logger,
    this._diagnostics,
  );

  final MoviePlaybackVariantResolver _resolver;
  final PlaybackSelectionService _selectionService;
  final PlaybackHistoryRepository _history;
  final AppLogger _logger;
  final PerformanceDiagnosticLogger _diagnostics;

  Future<PlaybackSelectionDecision> call({
    required String movieId,
    required String title,
    required PlaybackSelectionPreferences preferences,
    required PlaybackSelectionContext context,
    int? releaseYear,
    Uri? poster,
    String? userId,
    Set<String>? candidateSourceIds,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final variants = await _resolver.resolveVariants(
        movieId: movieId,
        title: title,
        releaseYear: releaseYear,
        poster: poster,
        candidateSourceIds: candidateSourceIds,
      );
      if (variants.isEmpty) {
        final decision = _selectionService.select(
          variants: const <PlaybackVariant>[],
          preferences: preferences,
          context: context,
        );
        _diagnostics.completed(
          'movie_playback_selection',
          elapsed: stopwatch.elapsed,
          result: decision.disposition.name,
          context: <String, Object?>{
            'movieId': movieId,
            'variants': 0,
            'reason': decision.reason.name,
          },
        );
        return decision;
      }

      final resumePosition = await _loadResumePosition(movieId, userId: userId);
      final variantsWithResume = resumePosition == null
          ? variants
          : variants
                .map(
                  (variant) => PlaybackVariant(
                    id: variant.id,
                    sourceId: variant.sourceId,
                    sourceLabel: variant.sourceLabel,
                    videoSource: _copyVideoSource(
                      variant.videoSource,
                      resumePosition: resumePosition,
                    ),
                    contentType: variant.contentType,
                    rawTitle: variant.rawTitle,
                    normalizedTitle: variant.normalizedTitle,
                    qualityLabel: variant.qualityLabel,
                    qualityRank: variant.qualityRank,
                    dynamicRangeLabel: variant.dynamicRangeLabel,
                    audioLanguageCode: variant.audioLanguageCode,
                    audioLanguageLabel: variant.audioLanguageLabel,
                    subtitleLanguageCode: variant.subtitleLanguageCode,
                    subtitleLanguageLabel: variant.subtitleLanguageLabel,
                    hasSubtitles: variant.hasSubtitles,
                  ),
                )
                .toList(growable: false);

      final decision = _selectionService.select(
        variants: variantsWithResume,
        preferences: preferences,
        context: context,
      );

      final hasExplicitPreferredSource =
          preferences.preferredSourceIds.length == 1;
      if (decision.requiresManualSelection && hasExplicitPreferredSource) {
        _logger.warn(
          'Movie playback selection remained ambiguous for movieId=$movieId despite a selected source',
          category: 'playback_selection',
        );
      }

      _diagnostics.completed(
        'movie_playback_selection',
        elapsed: stopwatch.elapsed,
        result: decision.disposition.name,
        context: <String, Object?>{
          'movieId': movieId,
          'variants': variantsWithResume.length,
          'reason': decision.reason.name,
          'hasResume': resumePosition != null,
        },
      );
      return decision;
    } catch (error, stackTrace) {
      _diagnostics.failed(
        'movie_playback_selection',
        elapsed: stopwatch.elapsed,
        error: error,
        stackTrace: stackTrace,
        context: <String, Object?>{'movieId': movieId},
      );
      rethrow;
    }
  }

  Future<Duration?> _loadResumePosition(
    String movieId, {
    String? userId,
  }) async {
    try {
      final entry = await _history.getEntry(
        movieId,
        ContentType.movie,
        userId: userId,
      );
      return entry?.lastPosition;
    } catch (_) {
      return null;
    }
  }

  VideoSource _copyVideoSource(VideoSource source, {Duration? resumePosition}) {
    return VideoSource(
      url: source.url,
      title: source.title,
      subtitle: source.subtitle,
      contentId: source.contentId,
      tmdbId: source.tmdbId,
      contentType: source.contentType,
      poster: source.poster,
      season: source.season,
      episode: source.episode,
      resumePosition: resumePosition,
    );
  }
}
