// lib/src/core/logging/logging_service.dart

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';

/// Backward compatible wrapper redirecting legacy calls to [AppLogger].
class LoggingService {
  static Future<void> init({String fileName = 'log.txt'}) async {}

  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!sl.isRegistered<AppLogger>()) return;
    sl<AppLogger>().log(
      level,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<void> dispose() async {}
}
