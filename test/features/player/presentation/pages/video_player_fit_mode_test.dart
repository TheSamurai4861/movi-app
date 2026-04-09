import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/presentation/pages/video_player_page.dart';

void main() {
  group('computeCoverScale', () {
    test('returns 1.0 when viewport and video share same ratio', () {
      expect(
        computeCoverScale(viewportAspectRatio: 16 / 9, videoAspectRatio: 16 / 9),
        1.0,
      );
    });

    test('scales up when viewport is wider than video', () {
      expect(
        computeCoverScale(viewportAspectRatio: 21 / 9, videoAspectRatio: 16 / 9),
        closeTo((21 / 9) / (16 / 9), 1e-9),
      );
    });

    test('scales up when viewport is taller than video', () {
      expect(
        computeCoverScale(viewportAspectRatio: 4 / 3, videoAspectRatio: 21 / 9),
        closeTo((21 / 9) / (4 / 3), 1e-9),
      );
    });

    test('returns 1.0 for invalid ratios', () {
      expect(
        computeCoverScale(viewportAspectRatio: 0, videoAspectRatio: 16 / 9),
        1.0,
      );
      expect(
        computeCoverScale(viewportAspectRatio: 16 / 9, videoAspectRatio: 0),
        1.0,
      );
    });
  });
}
