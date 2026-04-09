import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/tv/presentation/services/episode_playback_page_telemetry.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('builds a stable target episode payload with domain reason code', () {
    final decision = PlaybackSelectionDecision(
      disposition: PlaybackSelectionDisposition.autoPlay,
      reason: PlaybackSelectionReason.preferredSourceMatch,
      rankedVariants: <PlaybackVariant>[_variant()],
      selectedVariant: _variant(),
      launchPlan: _launchPlan(),
    );

    final context = EpisodePlaybackPageTelemetry.targetEpisodeSelectedContext(
      seriesId: '37854',
      seasonNumber: 2,
      episodeNumber: 15,
      decision: decision,
      selectedVariant: _variant(),
      startFromBeginning: false,
    );

    expect(context['seriesId'], '37854');
    expect(context['seasonNumber'], 2);
    expect(context['episodeNumber'], 15);
    expect(context['variantId'], 'xtream-a:101');
    expect(context['sourceId'], 'xtream-a');
    expect(context['selectionDisposition'], 'autoPlay');
    expect(context['selectionReason'], 'preferredSourceMatch');
    expect(context['resumeEligible'], isTrue);
    expect(context['domainResumeReasonCode'], 'applied');
    expect(context['resumeOverridden'], isFalse);
  });

  test('emits resume_applied when the page forwards a resume position', () {
    final decision = PlaybackSelectionDecision(
      disposition: PlaybackSelectionDisposition.autoPlay,
      reason: PlaybackSelectionReason.preferredSourceMatch,
      rankedVariants: <PlaybackVariant>[_variant()],
      selectedVariant: _variant(),
      launchPlan: _launchPlan(),
    );

    expect(
      EpisodePlaybackPageTelemetry.resumeEvent(
        startFromBeginning: false,
        selectedVariant: _variant(),
      ),
      'resume_applied',
    );
    expect(
      EpisodePlaybackPageTelemetry.resumeContext(
        seriesId: '37854',
        seasonNumber: 2,
        episodeNumber: 15,
        decision: decision,
        selectedVariant: _variant(),
        startFromBeginning: false,
      )['resumeReasonCode'],
      'applied',
    );
    expect(
      EpisodePlaybackPageTelemetry.resumeContext(
        seriesId: '37854',
        seasonNumber: 2,
        episodeNumber: 15,
        decision: decision,
        selectedVariant: _variant(),
        startFromBeginning: false,
      )['resumePositionMs'],
      const Duration(minutes: 7).inMilliseconds,
    );
  });

  test('emits resume_skipped with startFromBeginning reason code', () {
    final decision = PlaybackSelectionDecision(
      disposition: PlaybackSelectionDisposition.autoPlay,
      reason: PlaybackSelectionReason.preferredSourceMatch,
      rankedVariants: <PlaybackVariant>[_variant()],
      selectedVariant: _variant(),
      launchPlan: _launchPlan(),
    );

    expect(
      EpisodePlaybackPageTelemetry.resumeEvent(
        startFromBeginning: true,
        selectedVariant: _variant(),
      ),
      'resume_skipped',
    );
    expect(
      EpisodePlaybackPageTelemetry.resumeContext(
        seriesId: '37854',
        seasonNumber: 2,
        episodeNumber: 15,
        decision: decision,
        selectedVariant: _variant(),
        startFromBeginning: true,
      )['resumeReasonCode'],
      EpisodePlaybackPageTelemetry.startFromBeginningReasonCode,
    );
    expect(
      EpisodePlaybackPageTelemetry.resumeContext(
        seriesId: '37854',
        seasonNumber: 2,
        episodeNumber: 15,
        decision: decision,
        selectedVariant: _variant(),
        startFromBeginning: true,
      )['resumePositionMs'],
      isNull,
    );
  });
}

PlaybackVariant _variant() {
  return PlaybackVariant(
    id: 'xtream-a:101',
    sourceId: 'xtream-a',
    sourceLabel: 'Salon',
    videoSource: const VideoSource(
      url: 'https://provider.example/series/101-s02e15.mkv',
      contentId: '37854',
      contentType: ContentType.series,
      season: 2,
      episode: 15,
      resumePosition: Duration(minutes: 7),
    ),
    contentType: ContentType.series,
    rawTitle: 'One.Piece.1999.MULTI.1080p',
    normalizedTitle: 'One Piece',
  );
}

PlaybackLaunchPlan _launchPlan() {
  return PlaybackLaunchPlan(
    contentType: ContentType.series,
    targetContentId: '37854',
    season: 2,
    episode: 15,
    resumePosition: Duration(minutes: 7),
    reasonCode: ResumeReasonCode.applied,
    isResumeEligible: true,
  );
}
