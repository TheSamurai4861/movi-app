import 'dart:async';

enum LogLevel { debug, info, warn, error }

class LogEvent {
  LogEvent({
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? category;
  final Object? error;
  final StackTrace? stackTrace;
}

abstract class AppLogger {
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  });

  void debug(String message, {String? category}) =>
      log(LogLevel.debug, message, category: category);
  void info(String message, {String? category}) =>
      log(LogLevel.info, message, category: category);
  void warn(String message, {String? category}) =>
      log(LogLevel.warn, message, category: category);
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}

/// Optional lifecycle hook implemented by loggers holding resources.
abstract class LoggerLifecycle {
  FutureOr<void> dispose();
}
