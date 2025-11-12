import 'package:movi/src/core/logging/logger.dart';

class CategoryLogger extends AppLogger {
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
}