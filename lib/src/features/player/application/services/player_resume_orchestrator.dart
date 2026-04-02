import 'dart:async';

import 'package:flutter/foundation.dart';

typedef PlayerSeekTo = FutureOr<void> Function(Duration position);
typedef ResumeTelemetry = void Function(String result, Map<String, Object?> ctx);

/// Orchestrateur de reprise (MR-M2).
///
/// Rôle:
/// - attendre des préconditions (durée > 0 et compatible avec la reprise),
/// - appliquer `seekTo` au plus une fois,
/// - borner l'attente (timeout anti-hang),
/// - exposer des événements observables via [telemetry].
final class PlayerResumeOrchestrator {
  PlayerResumeOrchestrator({
    required Duration? requestedResume,
    required PlayerSeekTo seekTo,
    ResumeTelemetry? telemetry,
    Duration safetyMargin = const Duration(seconds: 1),
    Duration maxWait = const Duration(seconds: 4),
    DateTime Function()? now,
  }) : _requestedResume = requestedResume,
       _seekTo = seekTo,
       _telemetry = telemetry,
       _safetyMargin = safetyMargin,
       _maxWait = maxWait,
       _now = now ?? DateTime.now {
    _startedAt = _now();
  }

  final Duration? _requestedResume;
  final PlayerSeekTo _seekTo;
  final ResumeTelemetry? _telemetry;
  final Duration _safetyMargin;
  final Duration _maxWait;
  final DateTime Function() _now;

  late final DateTime _startedAt;
  bool _done = false;

  bool get isDone => _done;

  /// À appeler à chaque durée reportée par le backend.
  Future<void> onDuration(Duration reportedDuration) async {
    if (_done) return;

    final resume = _requestedResume;
    if (resume == null || resume <= Duration.zero) {
      _done = true;
      _telemetry?.call('skip_no_resume', <String, Object?>{});
      return;
    }

    if (_isTimedOut()) {
      _done = true;
      _telemetry?.call(
        'skip_timeout',
        <String, Object?>{
          'resumeMs': resume.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
          'timeoutMs': _maxWait.inMilliseconds,
        },
      );
      return;
    }

    if (reportedDuration <= Duration.zero) {
      _telemetry?.call(
        'wait_duration_zero',
        <String, Object?>{
          'resumeMs': resume.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
        },
      );
      return;
    }

    // Tant que la durée est plus courte que la reprise + marge, on attend un update.
    if (reportedDuration < resume + _safetyMargin) {
      _telemetry?.call(
        'wait_duration_not_ready_for_resume',
        <String, Object?>{
          'resumeMs': resume.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
        },
      );
      return;
    }

    final maxSeek = reportedDuration > _safetyMargin
        ? reportedDuration - _safetyMargin
        : Duration.zero;
    if (maxSeek <= Duration.zero) {
      _telemetry?.call(
        'wait_duration_unstable',
        <String, Object?>{
          'resumeMs': resume.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
        },
      );
      return;
    }

    final target = resume <= maxSeek ? resume : maxSeek;
    if (target <= Duration.zero) {
      _done = true;
      _telemetry?.call(
        'skip_target_zero',
        <String, Object?>{
          'requestedMs': resume.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
        },
      );
      return;
    }

    _done = true; // anti-boucle / anti-race
    try {
      await _seekTo(target);
      _telemetry?.call(
        'applied',
        <String, Object?>{
          'requestedMs': resume.inMilliseconds,
          'appliedMs': target.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
        },
      );
    } catch (e) {
      // Fail-safe: ne pas retenter indéfiniment.
      _telemetry?.call(
        'seek_failed',
        <String, Object?>{
          'requestedMs': resume.inMilliseconds,
          'appliedMs': target.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
          'errorType': kDebugMode ? e.runtimeType.toString() : null,
        },
      );
    }
  }

  bool _isTimedOut() {
    final elapsed = _now().difference(_startedAt);
    return elapsed > _maxWait;
  }
}

