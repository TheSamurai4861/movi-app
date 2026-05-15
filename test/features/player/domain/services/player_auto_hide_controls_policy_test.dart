import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/domain/services/player_auto_hide_controls_policy.dart';

void main() {
  group('PlayerAutoHideControlsPolicy', () {
    test('shouldScheduleAutoHide only when controls visible and playing', () {
      expect(
        PlayerAutoHideControlsPolicy.shouldScheduleAutoHide(
          showControls: true,
          isPlaying: true,
        ),
        isTrue,
      );
      expect(
        PlayerAutoHideControlsPolicy.shouldScheduleAutoHide(
          showControls: true,
          isPlaying: false,
        ),
        isFalse,
      );
      expect(
        PlayerAutoHideControlsPolicy.shouldScheduleAutoHide(
          showControls: false,
          isPlaying: true,
        ),
        isFalse,
      );
    });

    test('shouldRunProgressPersistTimer depends only on playing', () {
      expect(
        PlayerAutoHideControlsPolicy.shouldRunProgressPersistTimer(
          isPlaying: true,
        ),
        isTrue,
      );
      expect(
        PlayerAutoHideControlsPolicy.shouldRunProgressPersistTimer(
          isPlaying: false,
        ),
        isFalse,
      );
    });
  });
}
