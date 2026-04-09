import 'package:movi/src/shared/domain/services/playback_resume_resolution.dart';

/// Règle métier partagée pour décider si une reprise est admissible.
Duration? normalizeResumePosition({
  required Duration? position,
  required Duration? duration,
}) {
  return resolvePlaybackResume(
    position: position,
    duration: duration,
  ).resumePosition;
}
