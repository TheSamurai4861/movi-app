import 'package:flutter/foundation.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/sanitizer/message_sanitizer.dart';

typedef ConsolePrinter = void Function(String message);

class ConsoleLogger extends AppLogger {
  ConsoleLogger({ConsolePrinter? printer, Set<String>? extraSensitiveKeys})
    : _printer = printer ?? debugPrint,
      _sanitizer = MessageSanitizer(extraSensitiveKeys: extraSensitiveKeys);

  final ConsolePrinter _printer;
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
    _printer(base);
    if (error != null) {
      _printer(' -> ${_sanitizer.sanitize('$error')}');
    }
    if (stackTrace != null) {
      _printer(stackTrace.toString());
    }
  }
}
