import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/application/services/player_resume_orchestrator.dart';

void main() {
  test('applies seek once when duration becomes compatible', () async {
    final seeks = <Duration>[];
    final events = <String>[];

    var now = DateTime(2026, 1, 1, 0, 0, 0);
    final orch = PlayerResumeOrchestrator(
      requestedResume: const Duration(minutes: 40),
      seekTo: (d) => seeks.add(d),
      telemetry: (r, _) => events.add(r),
      now: () => now,
      maxWait: const Duration(seconds: 10),
    );

    // Duration too short -> defer.
    await orch.onDuration(const Duration(minutes: 1));
    expect(seeks, isEmpty);
    expect(orch.isDone, isFalse);

    // Duration now covers resume -> apply once.
    await orch.onDuration(const Duration(minutes: 45));
    expect(seeks, [const Duration(minutes: 40)]);
    expect(orch.isDone, isTrue);

    // Spam does not re-apply.
    await orch.onDuration(const Duration(minutes: 46));
    expect(seeks, [const Duration(minutes: 40)]);
    expect(events.contains('applied'), isTrue);
  });

  test('marks done when seek throws (no retry loop)', () async {
    final events = <String>[];
    final orch = PlayerResumeOrchestrator(
      requestedResume: const Duration(minutes: 10),
      seekTo: (_) => throw StateError('boom'),
      telemetry: (r, _) => events.add(r),
      maxWait: const Duration(seconds: 10),
    );

    await orch.onDuration(const Duration(minutes: 20));
    expect(orch.isDone, isTrue);
    expect(events, contains('seek_failed'));
  });

  test('times out and does not seek', () async {
    final seeks = <Duration>[];
    final events = <String>[];

    var now = DateTime(2026, 1, 1, 0, 0, 0);
    final orch = PlayerResumeOrchestrator(
      requestedResume: const Duration(minutes: 40),
      seekTo: (d) => seeks.add(d),
      telemetry: (r, _) => events.add(r),
      now: () => now,
      maxWait: const Duration(seconds: 2),
    );

    await orch.onDuration(const Duration(seconds: 1)); // defer
    now = now.add(const Duration(seconds: 3)); // exceed maxWait
    await orch.onDuration(const Duration(seconds: 1)); // timeout path

    expect(seeks, isEmpty);
    expect(orch.isDone, isTrue);
    expect(events, contains('skip_timeout'));
  });
}

