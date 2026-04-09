import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/services/playback_resume_resolution.dart';

void main() {
  group('resolvePlaybackResume', () {
    test('returns resumable position and applied reason', () {
      final resolution = resolvePlaybackResume(
        position: const Duration(minutes: 12),
        duration: const Duration(hours: 2),
      );

      expect(resolution.canResume, isTrue);
      expect(resolution.resumePosition, const Duration(minutes: 12));
      expect(resolution.reasonCode, ResumeReasonCode.applied);
    });

    test('returns null position with stable skip reason', () {
      final resolution = resolvePlaybackResume(
        position: const Duration(seconds: 8),
        duration: const Duration(hours: 2),
      );

      expect(resolution.canResume, isFalse);
      expect(resolution.resumePosition, isNull);
      expect(resolution.reasonCode, ResumeReasonCode.progressOutOfRange);
    });
  });
}
