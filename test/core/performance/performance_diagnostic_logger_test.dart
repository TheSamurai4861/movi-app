import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';

void main() {
  group('PerformanceDiagnosticLogger', () {
    test('formats completion logs with elapsed time and context', () {
      final logger = _FakeLogger();
      final diagnostics = PerformanceDiagnosticLogger(logger);

      diagnostics.completed(
        'movie_variant_resolver',
        elapsed: const Duration(milliseconds: 42),
        context: const <String, Object?>{
          'movieId': '671',
          'playableVariants': 3,
        },
      );

      expect(logger.events, hasLength(1));
      final event = logger.events.single;
      expect(event.level, LogLevel.info);
      expect(event.category, 'performance_diagnostics');
      expect(event.message, contains('[PerfDiag]'));
      expect(event.message, contains('op=movie_variant_resolver'));
      expect(event.message, contains('event=completed'));
      expect(event.message, contains('durationMs=42'));
      expect(event.message, contains('movieId=671'));
      expect(event.message, contains('playableVariants=3'));
    });

    test('formats failed logs with warning level', () {
      final logger = _FakeLogger();
      final diagnostics = PerformanceDiagnosticLogger(logger);

      diagnostics.failed(
        'player_open_source',
        elapsed: const Duration(milliseconds: 87),
        error: StateError('boom'),
        context: const <String, Object?>{'contentId': 'xtream:12'},
      );

      expect(logger.events, hasLength(1));
      final event = logger.events.single;
      expect(event.level, LogLevel.warn);
      expect(event.message, contains('op=player_open_source'));
      expect(event.message, contains('event=failed'));
      expect(event.message, contains('durationMs=87'));
      expect(event.message, contains('result=error'));
      expect(event.message, contains('contentId=xtream:12'));
    });
  });
}

class _FakeLogger extends AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime(2026),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
