// lib/src/core/logging/logging_service.dart

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/logging_module.dart';

/// Backward compatible wrapper redirecting legacy calls to [AppLogger].
class LoggingService {
  /// Legacy init kept for compatibility.
  /// Now ensures the DI logger is registered (idempotent).
  static Future<void> init({String fileName = 'log.txt'}) async {
    // `fileName` is legacy; current implementation is driven by AppConfig.
    // We keep the parameter to avoid breaking call sites.
    LoggingModule.register();
  }

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

  /// Legacy dispose kept for compatibility.
  /// Now closes resources if the registered logger supports it.
  static Future<void> dispose() async {
    await LoggingModule.dispose();
  }
}
