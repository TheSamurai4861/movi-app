import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/application/services/player_resume_orchestrator.dart';

void main() {
  test('pause→reopen: a new resume session can apply again', () async {
    final seeks = <Duration>[];

    // Session #1 (before pause)
    final orch1 = PlayerResumeOrchestrator(
      requestedResume: const Duration(minutes: 10),
      seekTo: (d) => seeks.add(d),
      maxWait: const Duration(seconds: 10),
    );
    await orch1.onDuration(const Duration(minutes: 30));
    expect(orch1.isDone, isTrue);
    expect(seeks, [const Duration(minutes: 10)]);

    // Session #2 (after reopen)
    final orch2 = PlayerResumeOrchestrator(
      requestedResume: const Duration(minutes: 10),
      seekTo: (d) => seeks.add(d),
      maxWait: const Duration(seconds: 10),
    );
    await orch2.onDuration(const Duration(minutes: 30));
    expect(orch2.isDone, isTrue);
    expect(seeks, [const Duration(minutes: 10), const Duration(minutes: 10)]);
  });

  test('navigation fast dispose/recreate: timeout prevents hangs', () async {
    final seeks = <Duration>[];
    final events = <String>[];

    var now = DateTime(2026, 1, 1, 0, 0, 0);
    final orch = PlayerResumeOrchestrator(
      requestedResume: const Duration(minutes: 40),
      seekTo: (d) => seeks.add(d),
      telemetry: (r, _) => events.add(r),
      now: () => now,
      maxWait: const Duration(seconds: 1),
    );

    await orch.onDuration(const Duration(seconds: 1)); // not ready
    now = now.add(const Duration(seconds: 2)); // exceeds maxWait
    await orch.onDuration(const Duration(seconds: 1)); // timeout path

    expect(seeks, isEmpty);
    expect(orch.isDone, isTrue);
    expect(events, contains('skip_timeout'));
  });
}

