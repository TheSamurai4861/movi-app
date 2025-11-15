import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';

void main() {
  testWidgets('OverlaySplash renders logo and spinner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OverlaySplash(message: 'Préparation…')),
      ),
    );

    // Expect an Image (logo) and a CircularProgressIndicator (spinner)
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Préparation…'), findsOneWidget);
  });
}
