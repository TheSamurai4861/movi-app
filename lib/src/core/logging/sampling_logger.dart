import 'dart:math';

import 'package:movi/src/core/logging/logger.dart';

class SamplingLogger extends AppLogger implements LoggerLifecycle {
  SamplingLogger(
    this._inner, {
    Map<LogLevel, double>? samplingByLevel,
    Map<String, double>? samplingByCategory,
  })  : _samplingByLevel = samplingByLevel ?? const {},
        _samplingByCategory = samplingByCategory ?? const {},
        _rand = Random();

  final AppLogger _inner;
  final Map<LogLevel, double> _samplingByLevel;
  final Map<String, double> _samplingByCategory;
  final Random _rand;

  bool _accept(LogLevel level, String? category) {
    final catKey = (category == null || category.isEmpty) ? 'default' : category;
    final catProb = _samplingByCategory[catKey];
    final levelProb = _samplingByLevel[level];
    final p = catProb ?? levelProb ?? 1.0;
    if (p >= 1.0) return true;
    if (p <= 0.0) return false;
    return _rand.nextDouble() < p;
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_accept(level, category)) return;
    _inner.log(
      level,
      message,
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> dispose() async {
    // IMPORTANT: no ownership by default; let DI/root dispose the global logger.
  }
}
