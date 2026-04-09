import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';

class EpisodePlaybackPageTelemetry {
  const EpisodePlaybackPageTelemetry._();

  static const String operation = 'episode_play_action';
  static const String category = 'playback_page';
  static const String startFromBeginningReasonCode = 'startFromBeginning';
  static const String resumeUnavailableReasonCode = 'resumeUnavailable';

  static Map<String, Object?> targetEpisodeSelectedContext({
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required PlaybackSelectionDecision decision,
    required PlaybackVariant selectedVariant,
    required bool startFromBeginning,
  }) {
    return <String, Object?>{
      'seriesId': seriesId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'variantId': selectedVariant.id,
      'sourceId': selectedVariant.sourceId,
      'selectionDisposition': decision.disposition.name,
      'selectionReason': decision.reason.name,
      'resumeEligible': decision.resumeEligible,
      'domainResumeReasonCode': decision.resumeReasonCode?.name,
      'resumeOverridden': startFromBeginning,
    };
  }

  static String resumeEvent({
    required bool startFromBeginning,
    required PlaybackVariant selectedVariant,
  }) {
    if (startFromBeginning) {
      return 'resume_skipped';
    }
    if (selectedVariant.videoSource.resumePosition != null) {
      return 'resume_applied';
    }
    return 'resume_skipped';
  }

  static Map<String, Object?> resumeContext({
    required String seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required PlaybackSelectionDecision decision,
    required PlaybackVariant selectedVariant,
    required bool startFromBeginning,
  }) {
    final resumePosition = startFromBeginning
        ? null
        : selectedVariant.videoSource.resumePosition;
    return <String, Object?>{
      'seriesId': seriesId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'variantId': selectedVariant.id,
      'sourceId': selectedVariant.sourceId,
      'resumeEligible': decision.resumeEligible,
      'resumeReasonCode': resumeReasonCode(
        startFromBeginning: startFromBeginning,
        decision: decision,
      ),
      'domainResumeReasonCode': decision.resumeReasonCode?.name,
      'resumePositionMs': resumePosition?.inMilliseconds,
    };
  }

  static String resumeReasonCode({
    required bool startFromBeginning,
    required PlaybackSelectionDecision decision,
  }) {
    if (startFromBeginning) {
      return startFromBeginningReasonCode;
    }
    return decision.resumeReasonCode?.name ?? resumeUnavailableReasonCode;
  }
}
