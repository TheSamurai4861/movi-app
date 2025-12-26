import 'dart:async';

import 'package:movi/src/core/logging/logger.dart';

class RateLimitingLogger extends AppLogger implements LoggerLifecycle {
  RateLimitingLogger(
    this._inner, {
    this.defaultPerMinute = 0,
    Map<String, int>? perCategory,
    this.exposeMetrics = false,
    Duration? metricsInterval,
  })  : _limits = perCategory ?? const {},
        _metricsInterval = metricsInterval ?? const Duration(minutes: 1) {
    if (exposeMetrics) {
      _timer = Timer.periodic(_metricsInterval, (_) => _emitMetrics());
    }
  }

  final AppLogger _inner;
  final int defaultPerMinute;
  final Map<String, int> _limits;
  final bool exposeMetrics;
  final Duration _metricsInterval;
  Timer? _timer;

  final Map<String, _Window> _windows = <String, _Window>{};
  final Map<String, int> _dropped = <String, int>{};

  int _limitFor(String? category) {
    final key = (category == null || category.isEmpty) ? 'default' : category;
    return _limits[key] ?? defaultPerMinute;
  }

  bool _allow(String? category) {
    final now = DateTime.now();
    final key = (category == null || category.isEmpty) ? 'default' : category;
    final limit = _limitFor(category);
    if (limit <= 0) return true;

    final w = _windows.putIfAbsent(key, () => _Window(now));
    if (now.difference(w.start).inMinutes >= 1) {
      w.start = now;
      w.count = 0;
    }
    if (w.count < limit) {
      w.count++;
      return true;
    }
    _dropped[key] = (_dropped[key] ?? 0) + 1;
    return false;
  }

  void _emitMetrics() {
    if (_dropped.isEmpty) return;
    if (_timer != null && !_timer!.isActive) return;
    final entries = _dropped.entries.toList();
    _dropped.clear();
    for (final e in entries) {
      // Emit metrics directly to inner; bypasses rate limiting of this wrapper.
      _inner.info(
        'rate-limit dropped=${e.value}/min for category=${e.key}',
        category: 'metrics',
      );
    }
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_allow(category)) return;
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
    _timer?.cancel();
    if (exposeMetrics && _dropped.isNotEmpty) {
      _emitMetrics();
    }
    // IMPORTANT: no ownership by default; let DI/root dispose the global logger.
  }
}

class _Window {
  _Window(this.start);
  DateTime start;
  int count = 0;
}
