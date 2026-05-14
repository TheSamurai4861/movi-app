import 'package:movi/src/core/logging/logging_service.dart';
import 'package:movi/src/core/utils/unawaited.dart';

enum BootContractEvent {
  bootStateChanged('boot_state_changed'),
  bootActionTriggered('boot_action_triggered'),
  bootRunStarted('boot_run_started'),
  sourceConnected('source_connected'),
  sourceSelected('source_selected'),
  catalogPreparationStarted('catalog_preparation_started'),
  catalogPreparationCompleted('catalog_preparation_completed'),
  catalogPreparationFailed('catalog_preparation_failed'),
  bootRecoveryShown('boot_recovery_shown'),
  homePartialShown('home_partial_shown'),
  entryJourneyCompleted('entry_journey_completed');

  const BootContractEvent(this.wireName);

  final String wireName;
}

final class BootEventContractLogger {
  const BootEventContractLogger({required bool enabled}) : _enabled = enabled;

  final bool _enabled;

  bool get isEnabled => _enabled;

  void emit({
    required BootContractEvent event,
    required String runId,
    String? phase,
    String? reasonCode,
    int? durationMs,
    String? destination,
    String? action,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    if (!_enabled) return;

    final parts = <String>[
      'event=${event.wireName}',
      'run_id=${_encode(runId)}',
      if (phase != null && phase.trim().isNotEmpty) 'phase=${_encode(phase)}',
      if (reasonCode != null && reasonCode.trim().isNotEmpty)
        'reason_code=${_encode(reasonCode)}',
      if (durationMs != null) 'duration_ms=$durationMs',
      if (destination != null && destination.trim().isNotEmpty)
        'destination=${_encode(destination)}',
      if (action != null && action.trim().isNotEmpty)
        'action=${_encode(action)}',
    ];

    final sortedKeys = fields.keys.toList()..sort();
    for (final key in sortedKeys) {
      final value = fields[key];
      if (value == null) continue;
      parts.add('${_encode(key)}=${_encode(value)}');
    }

    unawaited(
      LoggingService.log(parts.join(' '), category: 'startup_contract'),
    );
  }

  String _encode(Object value) {
    final raw = value.toString().trim();
    if (raw.isEmpty) return 'empty';
    return raw.replaceAll(RegExp(r'\s+'), '_');
  }
}
