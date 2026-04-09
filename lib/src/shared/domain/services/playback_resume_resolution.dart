import 'package:flutter/foundation.dart';

import 'package:movi/src/shared/domain/services/media_resume_decision.dart';

/// Contrat domaine commun pour exprimer le résultat d'une reprise potentielle.
///
/// Il expose la position effectivement reprenable ainsi qu'un reason code
/// stable pour diagnostiquer pourquoi la reprise est appliquée ou refusée.
@immutable
class PlaybackResumeResolution {
  const PlaybackResumeResolution({
    required this.resumePosition,
    required this.reasonCode,
  });

  final Duration? resumePosition;
  final ResumeReasonCode reasonCode;

  bool get canResume => resumePosition != null;
}

PlaybackResumeResolution resolvePlaybackResume({
  required Duration? position,
  required Duration? duration,
}) {
  final decision = decideResume(position: position, duration: duration);
  return PlaybackResumeResolution(
    resumePosition: decision.positionOrNull,
    reasonCode: decision.reasonCode,
  );
}
