import 'package:movi/src/core/logging/logger.dart';

class PerformanceDiagnosticLogger {
  const PerformanceDiagnosticLogger(this._logger);

  final AppLogger _logger;

  void mark(
    String operation, {
    String event = 'mark',
    String category = 'performance_diagnostics',
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logger.info(
      _formatMessage(operation, event: event, context: context),
      category: category,
    );
  }

  void completed(
    String operation, {
    required Duration elapsed,
    String result = 'ok',
    String category = 'performance_diagnostics',
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logger.info(
      _formatMessage(
        operation,
        event: 'completed',
        elapsed: elapsed,
        result: result,
        context: context,
      ),
      category: category,
    );
  }

  void failed(
    String operation, {
    required Duration elapsed,
    Object? error,
    StackTrace? stackTrace,
    String category = 'performance_diagnostics',
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    _logger.log(
      LogLevel.warn,
      _formatMessage(
        operation,
        event: 'failed',
        elapsed: elapsed,
        result: 'error',
        context: context,
      ),
      category: category,
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _formatMessage(
    String operation, {
    required String event,
    Duration? elapsed,
    String? result,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final parts = <String>[
      '[PerfDiag]',
      'op=$operation',
      'event=$event',
      if (elapsed != null) 'durationMs=${elapsed.inMilliseconds}',
      if (result != null) 'result=$result',
    ];

    for (final entry in context.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      parts.add('${entry.key}=$value');
    }

    return parts.join(' ');
  }
}
