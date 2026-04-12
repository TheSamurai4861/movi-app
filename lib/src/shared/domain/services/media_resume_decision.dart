import 'package:flutter/foundation.dart';
import 'package:movi/src/features/library/library_constants.dart';

/// Reason codes stables pour la décision de reprise (MR-M1).
enum ResumeReasonCode {
  noPosition,
  positionInvalid,
  durationUnknown,
  durationInvalid,
  progressOutOfRange,
  nearEnd,
  applied,
}

@immutable
sealed class ResumeDecision {
  const ResumeDecision({required this.reasonCode});

  final ResumeReasonCode reasonCode;

  Duration? get positionOrNull => switch (this) {
    ResumeApply(:final position, reasonCode: _) => position,
    ResumeSkip() => null,
  };
}

final class ResumeApply extends ResumeDecision {
  const ResumeApply({required this.position, required super.reasonCode});

  final Duration position;
}

final class ResumeSkip extends ResumeDecision {
  const ResumeSkip({required super.reasonCode});
}

/// Décide la position de reprise en appliquant des règles déterministes.
///
/// Règles clés (MR-M1):
/// - `duration == null` => skip (`duration_unknown`)
/// - clamp position dans [0 ; duration - margin]
/// - skip si hors seuils de progrès (LibraryConstants)
ResumeDecision decideResume({
  required Duration? position,
  required Duration? duration,
  Duration nearEndMargin = const Duration(seconds: 5),
  double minProgress = LibraryConstants.inProgressMinThreshold,
  double maxProgress = LibraryConstants.inProgressMaxThreshold,
}) {
  if (position == null) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.noPosition);
  }
  if (position <= Duration.zero) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.positionInvalid);
  }

  if (duration == null) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.durationUnknown);
  }
  if (duration <= Duration.zero) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.durationInvalid);
  }

  final durationSeconds = duration.inSeconds;
  if (durationSeconds <= 0) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.durationInvalid);
  }

  final progress = position.inSeconds / durationSeconds;
  if (progress < minProgress || progress >= maxProgress) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.progressOutOfRange);
  }

  final maxSeek = duration - nearEndMargin;
  if (maxSeek <= Duration.zero) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.nearEnd);
  }

  final clamped = position <= maxSeek ? position : maxSeek;
  if (clamped <= Duration.zero) {
    return const ResumeSkip(reasonCode: ResumeReasonCode.positionInvalid);
  }

  return ResumeApply(position: clamped, reasonCode: ResumeReasonCode.applied);
}
