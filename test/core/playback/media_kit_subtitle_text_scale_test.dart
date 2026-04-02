import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/playback/media_kit_subtitle_text_scale.dart';

void main() {
  group('MediaKitSubtitleTextScale.linearFactor', () {
    test('returns 1.0 for reference 1920x1080 viewport', () {
      expect(
        MediaKitSubtitleTextScale.linearFactor(
          layoutWidth: MediaKitSubtitleTextScale.kMediaKitSubtitleReferenceWidth,
          layoutHeight:
              MediaKitSubtitleTextScale.kMediaKitSubtitleReferenceHeight,
        ),
        1.0,
      );
    });

    test('matches sqrt(nr/dr) for phone landscape 16:9 order of magnitude', () {
      const w = 693.0;
      const h = 390.0;
      final nr = w * h;
      final dr = MediaKitSubtitleTextScale.kMediaKitSubtitleReferenceWidth *
          MediaKitSubtitleTextScale.kMediaKitSubtitleReferenceHeight;
      final expected = math.sqrt((nr / dr).clamp(0.0, 1.0));
      expect(
        MediaKitSubtitleTextScale.linearFactor(
          layoutWidth: w,
          layoutHeight: h,
        ),
        closeTo(expected, 1e-12),
      );
    });

    test('returns 0.0 when width is zero', () {
      expect(
        MediaKitSubtitleTextScale.linearFactor(
          layoutWidth: 0,
          layoutHeight: 500,
        ),
        0.0,
      );
    });

    test('returns 0.0 when product is non-positive (negative width)', () {
      expect(
        MediaKitSubtitleTextScale.linearFactor(
          layoutWidth: -10,
          layoutHeight: 500,
        ),
        0.0,
      );
    });

    test('caps at 1.0 when area exceeds reference', () {
      expect(
        MediaKitSubtitleTextScale.linearFactor(
          layoutWidth: 4000,
          layoutHeight: 3000,
        ),
        1.0,
      );
    });
  });
}
