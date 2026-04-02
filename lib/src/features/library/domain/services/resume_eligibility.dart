import 'package:movi/src/shared/domain/services/media_resume_decision.dart';

/// Règle métier partagée pour décider si une reprise est admissible.
Duration? normalizeResumePosition({
  required Duration? position,
  required Duration? duration,
}) {
  return decideResume(position: position, duration: duration).positionOrNull;
}
