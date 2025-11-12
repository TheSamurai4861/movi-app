import 'package:flutter/foundation.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/sanitizer/message_sanitizer.dart';

class ConsoleLogger extends AppLogger {
  ConsoleLogger() : _sanitizer = MessageSanitizer();

  final MessageSanitizer _sanitizer;
  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final ts = DateTime.now().toIso8601String();
    final tag = level.name.toUpperCase();
    final cat = (category == null || category.isEmpty)
        ? ''
        : '[${_sanitizer.sanitize(category)}] ';
    final base = '[$ts][$tag] $cat${_sanitizer.sanitize(message)}';
    debugPrint(base);
    if (error != null) {
      debugPrint(' -> ${_sanitizer.sanitize('$error')}');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
