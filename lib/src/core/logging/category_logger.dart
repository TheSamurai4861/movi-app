import 'package:movi/src/core/logging/logger.dart';

class CategoryLogger extends AppLogger implements LoggerLifecycle {
  CategoryLogger(
    this._inner,
    this._category, {
    this.disposeInner = false,
  });

  final AppLogger _inner;
  final String _category;

  /// Wrappers should NOT dispose the shared/global logger by default.
  /// Set to true only if this wrapper truly owns the inner instance.
  final bool disposeInner;

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _inner.log(
      level,
      message,
      category: _category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> dispose() async {
    if (!disposeInner) return;
    if (_inner is LoggerLifecycle) {
      await (_inner as LoggerLifecycle).dispose();
    }
  }
}
