import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';

void main() {
  group('decideResume', () {
    test('skip when position is null', () {
      final d = decideResume(position: null, duration: const Duration(minutes: 10));
      expect(d.positionOrNull, isNull);
      expect(d.reasonCode, ResumeReasonCode.noPosition);
    });

    test('skip when position is zero/negative', () {
      expect(
        decideResume(
          position: Duration.zero,
          duration: const Duration(minutes: 10),
        ).reasonCode,
        ResumeReasonCode.positionInvalid,
      );
      expect(
        decideResume(
          position: const Duration(seconds: -1),
          duration: const Duration(minutes: 10),
        ).reasonCode,
        ResumeReasonCode.positionInvalid,
      );
    });

    test('skip when duration is null or invalid', () {
      expect(
        decideResume(
          position: const Duration(seconds: 10),
          duration: null,
        ).reasonCode,
        ResumeReasonCode.durationUnknown,
      );
      expect(
        decideResume(
          position: const Duration(seconds: 10),
          duration: Duration.zero,
        ).reasonCode,
        ResumeReasonCode.durationInvalid,
      );
    });

    test('skip when progress is out of range', () {
      final tooEarly = decideResume(
        position: const Duration(seconds: 1),
        duration: const Duration(hours: 1),
      );
      expect(tooEarly.reasonCode, ResumeReasonCode.progressOutOfRange);

      final tooLate = decideResume(
        position: const Duration(minutes: 59, seconds: 59),
        duration: const Duration(hours: 1),
      );
      expect(tooLate.reasonCode, ResumeReasonCode.progressOutOfRange);
    });

    test('clamps to duration - margin', () {
      final d = decideResume(
        position: const Duration(seconds: 200),
        duration: const Duration(seconds: 100),
        nearEndMargin: const Duration(seconds: 5),
        minProgress: 0,
        maxProgress: 10,
      );
      expect(d.positionOrNull, const Duration(seconds: 95));
      expect(d.reasonCode, ResumeReasonCode.applied);
    });

    test('near end yields skip', () {
      final d = decideResume(
        position: const Duration(seconds: 1),
        duration: const Duration(seconds: 4),
        nearEndMargin: const Duration(seconds: 5),
        minProgress: 0,
        maxProgress: 10,
      );
      expect(d.positionOrNull, isNull);
      expect(d.reasonCode, ResumeReasonCode.nearEnd);
    });

    test('idempotent for same inputs', () {
      final a = decideResume(
        position: const Duration(minutes: 10),
        duration: const Duration(hours: 2),
      );
      final b = decideResume(
        position: const Duration(minutes: 10),
        duration: const Duration(hours: 2),
      );
      expect(a.reasonCode, b.reasonCode);
      expect(a.positionOrNull, b.positionOrNull);
    });
  });
}

