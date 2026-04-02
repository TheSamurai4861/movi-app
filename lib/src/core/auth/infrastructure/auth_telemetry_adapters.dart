import 'package:flutter/foundation.dart';

import 'package:movi/src/core/auth/application/ports/auth_telemetry_port.dart';
import 'package:movi/src/core/auth/domain/entities/auth_failures.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/operation_context.dart';

/// Minimal telemetry that logs structured events.
///
/// - Always correlation-friendly (opId when present)
/// - Never includes secrets/PII
final class AuthLoggerTelemetryAdapter implements AuthTelemetryPort {
  AuthLoggerTelemetryAdapter({AppLogger? logger}) : _logger = logger;

  final AppLogger? _logger;

  @override
  void event({
    required String action,
    required String result,
    AuthFailureCode? reasonCode,
    String? detail,
  }) {
    final op = currentOperationId();
    final opPart = op == null ? '' : ' opId=$op';
    final reasonPart = reasonCode == null ? '' : ' reasonCode=${reasonCode.name}';
    final detailPart = detail == null ? '' : ' detail=$detail';

    final msg =
        'feature=auth action=$action result=$result$reasonPart$opPart$detailPart';

    final logger = _logger;
    if (logger != null) {
      // Keep auth telemetry at info by default.
      logger.info(msg, category: 'auth');
      return;
    }

    if (kDebugMode) {
      debugPrint('[Auth] $msg');
    }
  }
}

