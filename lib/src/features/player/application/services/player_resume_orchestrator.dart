import 'dart:async';

import 'package:flutter/foundation.dart';

typedef PlayerSeekTo = FutureOr<void> Function(Duration position);
typedef ResumeTelemetry =
    void Function(String result, Map<String, Object?> ctx);

/// Orchestrateur de reprise (MR-M2).
///
/// Rôle:
/// - attendre des préconditions (durée > 0 et compatible avec la reprise),
/// - appliquer `seekTo` au plus une fois par tentative contrôlée,
/// - confirmer la reprise via le flux de position,
/// - tolérer une réinitialisation tardive du backend (ex: retour à 0 après un seek),
/// - borner l'attente (timeout anti-hang),
/// - exposer des événements observables via [telemetry].
final class PlayerResumeOrchestrator {
  PlayerResumeOrchestrator({
    required Duration? requestedResume,
    required PlayerSeekTo seekTo,
    ResumeTelemetry? telemetry,
    Duration safetyMargin = const Duration(seconds: 1),
    Duration maxWait = const Duration(seconds: 10),
    Duration seekConfirmationTolerance = const Duration(seconds: 2),
    int maxReseekAttempts = 2,
    Duration stableConfirmation = const Duration(seconds: 2),
    DateTime Function()? now,
  }) : _requestedResume = requestedResume,
       _seekTo = seekTo,
       _telemetry = telemetry,
       _safetyMargin = safetyMargin,
       _maxWait = maxWait,
       _seekConfirmationTolerance = seekConfirmationTolerance,
       _maxReseekAttempts = maxReseekAttempts,
       _stableConfirmation = stableConfirmation,
       _now = now ?? DateTime.now {
    _startedAt = _now();
  }

  final Duration? _requestedResume;
  final PlayerSeekTo _seekTo;
  final ResumeTelemetry? _telemetry;
  final Duration _safetyMargin;
  final Duration _maxWait;
  final Duration _seekConfirmationTolerance;
  final int _maxReseekAttempts;
  final Duration _stableConfirmation;
  final DateTime Function() _now;

  late final DateTime _startedAt;
  bool _done = false;
  bool _seekIssued = false;
  int _reseekAttempts = 0;
  Duration? _appliedTarget;
  DateTime? _confirmedAt;

  bool get isDone => _done;
  bool get requiresResume => _hasRequestedResume;
  Duration? get appliedTarget => _appliedTarget;

  /// À appeler à chaque durée reportée par le backend.
  Future<void> onDuration(Duration reportedDuration) async {
    if (_done) {
      return;
    }

    final resume = _requestedResume;
    if (!_hasRequestedResume || resume == null) {
      _settle('skip_no_resume', <String, Object?>{});
      return;
    }

    if (_isTimedOut()) {
      _settle(
        _seekIssued ? 'verify_timeout' : 'skip_timeout',
        <String, Object?>{
          'resumeMs': resume.inMilliseconds,
          'durationMs': reportedDuration.inMilliseconds,
          'timeoutMs': _maxWait.inMilliseconds,
          'reseekAttempts': _reseekAttempts,
        },
      );
      return;
    }

    if (reportedDuration <= Duration.zero) {
      _telemetry?.call('wait_duration_zero', <String, Object?>{
        'resumeMs': resume.inMilliseconds,
        'durationMs': reportedDuration.inMilliseconds,
      });
      return;
    }

    if (reportedDuration < resume + _safetyMargin) {
      _telemetry?.call('wait_duration_not_ready_for_resume', <String, Object?>{
        'resumeMs': resume.inMilliseconds,
        'durationMs': reportedDuration.inMilliseconds,
      });
      return;
    }

    final maxSeek = reportedDuration > _safetyMargin
        ? reportedDuration - _safetyMargin
        : Duration.zero;
    if (maxSeek <= Duration.zero) {
      _telemetry?.call('wait_duration_unstable', <String, Object?>{
        'resumeMs': resume.inMilliseconds,
        'durationMs': reportedDuration.inMilliseconds,
      });
      return;
    }

    final target = resume <= maxSeek ? resume : maxSeek;
    if (target <= Duration.zero) {
      _settle('skip_target_zero', <String, Object?>{
        'requestedMs': resume.inMilliseconds,
        'durationMs': reportedDuration.inMilliseconds,
      });
      return;
    }

    if (_seekIssued && _appliedTarget == target) {
      _telemetry?.call('wait_position_confirmation', <String, Object?>{
        'requestedMs': resume.inMilliseconds,
        'appliedMs': target.inMilliseconds,
        'durationMs': reportedDuration.inMilliseconds,
        'reseekAttempts': _reseekAttempts,
      });
      return;
    }

    await _issueSeek(
      target,
      reason: _seekIssued ? 'duration_recovery' : 'initial_apply',
      reportedDuration: reportedDuration,
    );
  }

  /// À appeler à chaque position reportée par le backend.
  Future<void> onPosition(Duration reportedPosition) async {
    if (_done || !_seekIssued) {
      return;
    }

    final target = _appliedTarget;
    if (target == null || target <= Duration.zero) {
      return;
    }

    if (_isWithinTolerance(reportedPosition, target)) {
      final now = _now();
      final confirmedAt = _confirmedAt;
      if (confirmedAt == null) {
        _confirmedAt = now;
        _telemetry?.call('applied_confirmed_candidate', <String, Object?>{
          'appliedMs': target.inMilliseconds,
          'positionMs': reportedPosition.inMilliseconds,
          'stableMs': _stableConfirmation.inMilliseconds,
          'reseekAttempts': _reseekAttempts,
        });
        return;
      }

      if (now.difference(confirmedAt) >= _stableConfirmation) {
        _settle('applied_confirmed', <String, Object?>{
          'appliedMs': target.inMilliseconds,
          'positionMs': reportedPosition.inMilliseconds,
          'stableMs': _stableConfirmation.inMilliseconds,
          'reseekAttempts': _reseekAttempts,
        });
      }
      return;
    }

    // Not within tolerance anymore -> reset stability window.
    _confirmedAt = null;

    if (_isTimedOut()) {
      _settle('verify_timeout', <String, Object?>{
        'appliedMs': target.inMilliseconds,
        'positionMs': reportedPosition.inMilliseconds,
        'timeoutMs': _maxWait.inMilliseconds,
        'reseekAttempts': _reseekAttempts,
      });
      return;
    }

    if (_isMaterialRegression(reportedPosition, target) &&
        _reseekAttempts < _maxReseekAttempts) {
      _reseekAttempts += 1;
      await _issueSeek(
        target,
        reason: 'position_regression_repair',
        reportedPosition: reportedPosition,
      );
      return;
    }

    _telemetry?.call('wait_position_confirmation', <String, Object?>{
      'appliedMs': target.inMilliseconds,
      'positionMs': reportedPosition.inMilliseconds,
      'toleranceMs': _seekConfirmationTolerance.inMilliseconds,
      'reseekAttempts': _reseekAttempts,
    });
  }

  bool get _hasRequestedResume {
    final resume = _requestedResume;
    return resume != null && resume > Duration.zero;
  }

  Future<void> _issueSeek(
    Duration target, {
    required String reason,
    Duration? reportedDuration,
    Duration? reportedPosition,
  }) async {
    _seekIssued = true;
    _appliedTarget = target;

    try {
      await _seekTo(target);
      _telemetry?.call('seek_issued', <String, Object?>{
        'reason': reason,
        'appliedMs': target.inMilliseconds,
        'durationMs': reportedDuration?.inMilliseconds,
        'positionMs': reportedPosition?.inMilliseconds,
        'reseekAttempts': _reseekAttempts,
      });
    } catch (e) {
      _settle('seek_failed', <String, Object?>{
        'reason': reason,
        'appliedMs': target.inMilliseconds,
        'durationMs': reportedDuration?.inMilliseconds,
        'positionMs': reportedPosition?.inMilliseconds,
        'reseekAttempts': _reseekAttempts,
        'errorType': kDebugMode ? e.runtimeType.toString() : null,
      });
    }
  }

  void _settle(String result, Map<String, Object?> ctx) {
    if (_done) {
      return;
    }
    _done = true;
    _telemetry?.call(result, ctx);
  }

  bool _isTimedOut() {
    final elapsed = _now().difference(_startedAt);
    return elapsed > _maxWait;
  }

  bool _isWithinTolerance(Duration reportedPosition, Duration target) {
    final deltaMs = (reportedPosition.inMilliseconds - target.inMilliseconds)
        .abs();
    return deltaMs <= _seekConfirmationTolerance.inMilliseconds;
  }

  bool _isMaterialRegression(Duration reportedPosition, Duration target) {
    return reportedPosition + _seekConfirmationTolerance < target;
  }
}
