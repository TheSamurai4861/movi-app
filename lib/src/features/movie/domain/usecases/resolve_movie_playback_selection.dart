import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/domain/services/movie_playback_variant_resolver.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/services/playback_resume_resolution.dart';
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

      final resumeResolution = await _loadResumeResolution(
        movieId,
        userId: userId,
      );
      final resumePosition = resumeResolution.resumePosition;
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
      final enrichedDecision = PlaybackSelectionDecision(
        disposition: decision.disposition,
        reason: decision.reason,
        rankedVariants: decision.rankedVariants,
        selectedVariant: decision.selectedVariant,
        launchPlan: PlaybackLaunchPlan(
          contentType: ContentType.movie,
          targetContentId: movieId,
          resumePosition: resumeResolution.resumePosition,
          reasonCode: resumeResolution.reasonCode,
          isResumeEligible: resumeResolution.canResume,
        ),
      );

      final hasExplicitPreferredSource =
          preferences.preferredSourceIds.length == 1;
      if (enrichedDecision.requiresManualSelection &&
          hasExplicitPreferredSource) {
        _logger.warn(
          'Movie playback selection remained ambiguous for movieId=$movieId despite a selected source',
          category: 'playback_selection',
        );
      }

      _diagnostics.completed(
        'movie_playback_selection',
        elapsed: stopwatch.elapsed,
        result: enrichedDecision.disposition.name,
        context: <String, Object?>{
          'movieId': movieId,
          'variants': variantsWithResume.length,
          'reason': enrichedDecision.reason.name,
          'resumeRequested': resumeResolution.canResume,
          'resumeApplied':
              enrichedDecision.selectedVariant?.videoSource.resumePosition !=
              null,
          'resumeReasonCode': resumeResolution.reasonCode.name,
        },
      );
      return enrichedDecision;
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

  Future<PlaybackResumeResolution> _loadResumeResolution(
    String movieId, {
    String? userId,
  }) async {
    try {
      final entry = await _history.getEntry(
        movieId,
        ContentType.movie,
        userId: userId,
      );
      final resolution = resolvePlaybackResume(
        position: entry?.lastPosition,
        duration: entry?.duration,
      );
      _diagnostics.mark(
        'movie_resume_resolution',
        event: resolution.canResume ? 'resume_eligible' : 'resume_skipped',
        context: <String, Object?>{
          'movieId': movieId,
          'contentType': ContentType.movie.name,
          'hasEntry': entry != null,
          'positionMs': entry?.lastPosition?.inMilliseconds,
          'durationMs': entry?.duration?.inMilliseconds,
          'reasonCode': resolution.reasonCode.name,
        },
      );
      return resolution;
    } catch (_) {
      return const PlaybackResumeResolution(
        resumePosition: null,
        reasonCode: ResumeReasonCode.positionInvalid,
      );
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
