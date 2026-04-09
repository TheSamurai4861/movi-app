import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/widgets/movi_asset_icon.dart';

void main() {
  testWidgets('falls back to a local icon when an svg asset cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MoviAssetIcon(
            'assets/icons/actions/does_not_exist.svg',
            size: 24,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
