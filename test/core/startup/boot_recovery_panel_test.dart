import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_recovery_panel.dart';

void main() {
  testWidgets('primary autofocus puis Tab vers action secondaire', (
    tester,
  ) async {
    final primaryFocus = FocusNode(debugLabel: 'primary');
    final secondaryFocus = FocusNode(debugLabel: 'secondary');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BootRecoveryPanel(
            message: 'Message',
            severity: BootScreenSeverity.info,
            primaryLabel: 'Continuer',
            onPrimary: () {},
            secondaryLabel: 'Annuler',
            onSecondary: () {},
            primaryFocusNode: primaryFocus,
            secondaryFocusNode: secondaryFocus,
            primaryAutofocus: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(primaryFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(secondaryFocus.hasFocus, isTrue);
  });

  testWidgets('fromBootModel respecte primaryAutofocus selon initialFocus', (
    tester,
  ) async {
    final primaryFocus = FocusNode();
    const model = BootScreenModel(
      screenType: BootScreenType.actionRequired,
      message: 'M',
      reasonCode: 'test',
      isInteractive: true,
      initialFocus: BootFocusTarget.none,
      severity: BootScreenSeverity.warning,
      showLogo: true,
      showProgress: false,
      primaryAction: BootActionIntent.retry,
      primaryActionLabel: 'Reessayer',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BootRecoveryPanel.fromBootModel(
            model: model,
            onAction: (_) {},
            primaryFocusNode: primaryFocus,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(primaryFocus.hasFocus, isFalse);
  });

  testWidgets('panneau reste dans la largeur sur viewport etroit', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BootRecoveryPanel(
            message: 'Court',
            severity: BootScreenSeverity.info,
            primaryLabel: 'OK',
            onPrimary: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
