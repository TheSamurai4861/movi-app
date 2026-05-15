import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/images/image_decode_size.dart';

void main() {
  group('ImageDecodeSize', () {
    testWidgets('caps decode pixels on TV layout', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));

        late int? decodeWidth;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                decodeWidth =
                    ImageDecodeSize.decodePixelForLogical(context, 400);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(decodeWidth, lessThanOrEqualTo(960));
        expect(decodeWidth, greaterThanOrEqualTo(120));
      } finally {
        debugDefaultTargetPlatformOverride = null;
        await tester.binding.setSurfaceSize(null);
      }
    });

    testWidgets('uses higher cap on mobile layout', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late int? decodeWidth;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              decodeWidth = ImageDecodeSize.decodePixelForLogical(context, 400);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final dpr = tester.view.devicePixelRatio;
      final expected = (400 * dpr * 2).round().clamp(120, 1280);
      expect(decodeWidth, expected);
    });
  });
}
