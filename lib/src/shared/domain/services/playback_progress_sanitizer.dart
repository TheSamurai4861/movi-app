import 'package:flutter/foundation.dart';

@immutable
class SanitizedPlaybackProgress {
  const SanitizedPlaybackProgress({
    required this.position,
    required this.duration,
    required this.reasonCode,
  });

  final Duration? position;
  final Duration? duration;
  final String reasonCode;
}

/// Normalise les valeurs position/durée avant persistance.
///
/// Règles (MR-M3):
/// - durée <= 0 => durée = null
/// - position <= 0 => position = null
/// - si durée connue: clamp position dans [0 ; durée]
SanitizedPlaybackProgress sanitizePlaybackProgress({
  required Duration? position,
  required Duration? duration,
}) {
  final d = (duration == null || duration <= Duration.zero) ? null : duration;
  final p = (position == null || position <= Duration.zero) ? null : position;

  if (p == null && d == null) {
    return const SanitizedPlaybackProgress(
      position: null,
      duration: null,
      reasonCode: 'drop_invalid',
    );
  }

  if (p == null) {
    return SanitizedPlaybackProgress(
      position: null,
      duration: d,
      reasonCode: 'drop_position_invalid',
    );
  }

  if (d == null) {
    return SanitizedPlaybackProgress(
      position: p,
      duration: null,
      reasonCode: 'keep_duration_unknown',
    );
  }

  final clamped = p <= d ? p : d;
  if (clamped != p) {
    return SanitizedPlaybackProgress(
      position: clamped,
      duration: d,
      reasonCode: 'clamp_position_to_duration',
    );
  }

  return SanitizedPlaybackProgress(position: p, duration: d, reasonCode: 'ok');
}
