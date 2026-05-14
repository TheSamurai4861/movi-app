import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

void main() {
  testWidgets('affiche logo, message et pas de bouton', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BootSimpleLoadingScreen(
              message: 'Verification de la session',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MoviAssetIcon), findsOneWidget);
    expect(find.textContaining('Verification de la session'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('forBootModel aligne chargement simple', (tester) async {
    const model = BootScreenModel(
      screenType: BootScreenType.simpleLoading,
      message: 'Preparation du lancement',
      reasonCode: 'technical_startup',
      isInteractive: false,
      initialFocus: BootFocusTarget.none,
      severity: BootScreenSeverity.info,
      showLogo: true,
      showProgress: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BootSimpleLoadingScreen.forBootModel(model),
          ),
        ),
      ),
    );

    expect(find.byType(MoviAssetIcon), findsOneWidget);
    expect(find.textContaining('Preparation du lancement'), findsOneWidget);
  });

  testWidgets('viewport 393x852 et message long sans exception', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;

    final longMessage = List<String>.filled(40, 'segment').join(' ');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BootSimpleLoadingScreen(
              message: longMessage,
              secondaryMessage: longMessage,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
