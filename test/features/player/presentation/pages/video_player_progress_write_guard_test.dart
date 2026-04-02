import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/presentation/pages/video_player_page.dart';

void main() {
  group('shouldAcceptProgressWrite', () {
    test('accepts when there is no previous persisted position', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: null,
        candidatePosition: const Duration(seconds: 10),
      );
      expect(accepted, isTrue);
    });

    test('rejects low candidate when previous is much higher', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: const Duration(minutes: 40),
        candidatePosition: const Duration(seconds: 8),
      );
      expect(accepted, isFalse);
    });

    test('accepts minor backward jitter within tolerance', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: const Duration(minutes: 40),
        candidatePosition: const Duration(minutes: 39, seconds: 50),
      );
      expect(accepted, isTrue);
    });

    test('rejects candidate at 0s', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: const Duration(minutes: 10),
        candidatePosition: Duration.zero,
      );
      expect(accepted, isFalse);
    });

    test('accepts candidate exactly at backward tolerance threshold', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: const Duration(minutes: 40),
        candidatePosition: const Duration(minutes: 39, seconds: 45),
      );
      expect(accepted, isTrue);
    });

    test('rejects candidate just below backward tolerance threshold', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: const Duration(minutes: 40),
        candidatePosition: const Duration(minutes: 39, seconds: 44),
      );
      expect(accepted, isFalse);
    });

    test('accepts forward progress after an existing position', () {
      final accepted = shouldAcceptProgressWrite(
        previousPosition: const Duration(minutes: 40),
        candidatePosition: const Duration(minutes: 41),
      );
      expect(accepted, isTrue);
    });
  });

  group('shouldDeferResumeUntilDurationCoversResume', () {
    test(
      'defers when reported duration is shorter than resume plus margin',
      () {
        final defer = shouldDeferResumeUntilDurationCoversResume(
          reportedDuration: const Duration(seconds: 5),
          resumePosition: const Duration(minutes: 40),
        );
        expect(defer, isTrue);
      },
    );

    test('does not defer once duration covers resume with margin', () {
      final defer = shouldDeferResumeUntilDurationCoversResume(
        reportedDuration: const Duration(minutes: 45),
        resumePosition: const Duration(minutes: 40),
      );
      expect(defer, isFalse);
    });

    test('does not defer for zero resume', () {
      final defer = shouldDeferResumeUntilDurationCoversResume(
        reportedDuration: const Duration(seconds: 2),
        resumePosition: Duration.zero,
      );
      expect(defer, isFalse);
    });
  });

  group('shouldPersistOnDispose', () {
    test('skips dispose persist when back already handled persistence', () {
      final shouldPersist = shouldPersistOnDispose(skipDisposePersist: true);
      expect(shouldPersist, isFalse);
    });

    test('persists on dispose when back did not handle persistence', () {
      final shouldPersist = shouldPersistOnDispose(skipDisposePersist: false);
      expect(shouldPersist, isTrue);
    });
  });
}
