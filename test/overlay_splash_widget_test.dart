import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';

void main() {
  testWidgets('OverlaySplash renders logo and spinner', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: OverlaySplash(message: 'Préparation…')),
        ),
      ),
    );

    // Expect an SvgPicture (logo) et un CircularProgressIndicator (spinner)
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Préparation…'), findsOneWidget);
  });
}
