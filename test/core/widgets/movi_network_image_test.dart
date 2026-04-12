import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_network_image.dart';

void main() {
  group('MoviNetworkImage', () {
    testWidgets('derives decode dimensions from widget size by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoviNetworkImage(
              'https://example.com/image.jpg',
              width: 200,
              height: 100,
            ),
          ),
        ),
      );

      final widget = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final dpr = tester.view.devicePixelRatio;
      expect(widget.maxWidthDiskCache, (200 * dpr).round());
      expect(widget.maxHeightDiskCache, (100 * dpr).round());
    });

    testWidgets('honors explicit cache dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoviNetworkImage(
              'https://example.com/image.jpg',
              width: 200,
              height: 100,
              cacheWidth: 640,
              cacheHeight: 360,
            ),
          ),
        ),
      );

      final widget = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(widget.maxWidthDiskCache, 640);
      expect(widget.maxHeightDiskCache, 360);
    });

    testWidgets('uses errorBuilder for empty urls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoviNetworkImage(
              '',
              errorBuilder: (_, __, ___) => const Text('invalid'),
            ),
          ),
        ),
      );

      expect(find.text('invalid'), findsOneWidget);
    });
  });
}
