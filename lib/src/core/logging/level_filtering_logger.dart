import 'package:movi/src/core/logging/logger.dart';

class LevelFilteringLogger extends AppLogger implements LoggerLifecycle {
  LevelFilteringLogger(
    this._inner,
    this._minLevel, [
    this._byCategory = const {},
  ]);

  final AppLogger _inner;
  final LogLevel _minLevel;
  final Map<String, LogLevel> _byCategory;

  bool _allow(LogLevel level, String? category) {
    final key = (category == null || category.isEmpty) ? 'default' : category;
    final catLevel = _byCategory[key];
    final min = catLevel ?? _minLevel;
    return level.index >= min.index;
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_allow(level, category)) return;
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
