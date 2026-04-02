import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:movi/src/core/logging/operation_context.dart';

class SentryBootstrap {
  static const String dsn = String.fromEnvironment('SENTRY_DSN');
  static const String environment =
      String.fromEnvironment('SENTRY_ENV', defaultValue: 'dev');
  static const String release =
      String.fromEnvironment('SENTRY_RELEASE', defaultValue: 'unknown');

  static bool get enabled => dsn.isNotEmpty;

  static Future<void> init({required Future<void> Function() appRunner}) async {
    if (!enabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.environment = environment;
        options.release = release;

        options.sendDefaultPii = false;
        options.attachThreads = true;
        options.enableAutoSessionTracking = true;

        options.beforeSend = (event, hint) {
          final opId = currentOperationId();
          if (opId == null || opId.isEmpty) return event;
          event.tags = <String, String>{
            ...?event.tags,
            'operationId': opId,
          };
          return event;
        };

        if (!kReleaseMode) {
          // Keep dev noise low by default.
          options.tracesSampleRate = 0.0;
        }
      },
      appRunner: appRunner,
    );
  }
}

