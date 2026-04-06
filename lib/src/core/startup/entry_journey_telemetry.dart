import 'package:movi/src/core/logging/logging_service.dart';
import 'package:movi/src/core/utils/unawaited.dart';

final class EntryJourneyTelemetry {
  const EntryJourneyTelemetry({required bool enabled}) : _enabled = enabled;

  final bool _enabled;

  bool get isEnabled => _enabled;

  void event({
    required String name,
    required String runId,
    String? result,
    String? phase,
    String? step,
    String? reasonCode,
    int? elapsedMs,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!_enabled) return;

    final parts = <String>[
      'feature=entry_journey',
      'event=$name',
      'runId=$runId',
      if (result != null) 'result=$result',
      if (phase != null) 'phase=$phase',
      if (step != null) 'step=$step',
      if (reasonCode != null) 'reasonCode=$reasonCode',
      if (elapsedMs != null) 'elapsedMs=$elapsedMs',
    ];

    final sortedKeys = fields.keys.toList()..sort();
    for (final key in sortedKeys) {
      final value = fields[key];
      if (value == null) continue;
      parts.add('$key=${_encode(value)}');
    }

    unawaited(LoggingService.log(parts.join(' '), category: 'entry_journey'));
  }

  String _encode(Object value) {
    if (value is bool || value is num) return value.toString();
    final raw = value.toString().trim();
    if (raw.isEmpty) return 'empty';
    return raw.replaceAll(RegExp(r'\s+'), '_');
  }
}
