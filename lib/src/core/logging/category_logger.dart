import 'package:movi/src/core/logging/logger.dart';

class CategoryLogger extends AppLogger implements LoggerLifecycle {
  CategoryLogger(this._inner, this._category);

  final AppLogger _inner;
  final String _category;

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _inner.log(level, message, category: _category, error: error, stackTrace: stackTrace);
  }

  @override
  Future<void> dispose() async {
    if (_inner is LoggerLifecycle) {
      await (_inner as LoggerLifecycle).dispose();
    }
  }
}
