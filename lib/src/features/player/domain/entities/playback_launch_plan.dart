import 'package:equatable/equatable.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/services/playback_resume_resolution.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

/// Contrat de lancement commun pour film et série.
///
/// Il porte la cible métier à ouvrir et la reprise effectivement admissible,
/// indépendamment de la variante de streaming choisie ensuite.
class PlaybackLaunchPlan extends Equatable {
  const PlaybackLaunchPlan({
    required this.contentType,
    required this.targetContentId,
    required this.reasonCode,
    required this.isResumeEligible,
    this.season,
    this.episode,
    this.resumePosition,
  });

  final ContentType contentType;
  final String targetContentId;
  final int? season;
  final int? episode;
  final Duration? resumePosition;
  final ResumeReasonCode reasonCode;
  final bool isResumeEligible;

  factory PlaybackLaunchPlan.fromPlaybackProgress({
    required ContentType contentType,
    required String targetContentId,
    int? season,
    int? episode,
    required Duration? position,
    required Duration? duration,
  }) {
    final resolution = resolvePlaybackResume(position: position, duration: duration);
    return PlaybackLaunchPlan(
      contentType: contentType,
      targetContentId: targetContentId,
      season: season,
      episode: episode,
      resumePosition: resolution.resumePosition,
      reasonCode: resolution.reasonCode,
      isResumeEligible: resolution.canResume,
    );
  }

  Duration? resolveResumePosition({required bool startFromBeginning}) {
    if (startFromBeginning) {
      return Duration.zero;
    }
    return resumePosition;
  }

  VideoSource buildVideoSource({
    required VideoSource source,
    bool startFromBeginning = false,
    String? title,
    String? subtitle,
    Uri? poster,
  }) {
    return VideoSource(
      url: source.url,
      title: title ?? source.title,
      subtitle: subtitle ?? source.subtitle,
      contentId: targetContentId,
      tmdbId: source.tmdbId,
      contentType: contentType,
      poster: poster ?? source.poster,
      season: season,
      episode: episode,
      resumePosition: resolveResumePosition(
        startFromBeginning: startFromBeginning,
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    contentType,
    targetContentId,
    season,
    episode,
    resumePosition,
    reasonCode,
    isResumeEligible,
  ];
}
