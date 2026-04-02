import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/shared/domain/services/playback_progress_sanitizer.dart';

void main() {
  test('drops invalid position and duration', () {
    final s = sanitizePlaybackProgress(position: Duration.zero, duration: Duration.zero);
    expect(s.position, isNull);
    expect(s.duration, isNull);
    expect(s.reasonCode, 'drop_invalid');
  });

  test('drops invalid position but keeps valid duration', () {
    final s = sanitizePlaybackProgress(
      position: const Duration(seconds: -1),
      duration: const Duration(minutes: 10),
    );
    expect(s.position, isNull);
    expect(s.duration, const Duration(minutes: 10));
    expect(s.reasonCode, 'drop_position_invalid');
  });

  test('keeps position when duration unknown', () {
    final s = sanitizePlaybackProgress(
      position: const Duration(seconds: 10),
      duration: null,
    );
    expect(s.position, const Duration(seconds: 10));
    expect(s.duration, isNull);
    expect(s.reasonCode, 'keep_duration_unknown');
  });

  test('clamps position to duration', () {
    final s = sanitizePlaybackProgress(
      position: const Duration(seconds: 100),
      duration: const Duration(seconds: 20),
    );
    expect(s.position, const Duration(seconds: 20));
    expect(s.duration, const Duration(seconds: 20));
    expect(s.reasonCode, 'clamp_position_to_duration');
  });
}

