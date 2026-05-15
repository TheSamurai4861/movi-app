import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_catalog_loading_screen.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_recovery_panel.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_screen_renderer.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('BootScreenRenderer', () {
    testWidgets('rend un chargement simple sans panneau recovery', (
      tester,
    ) async {
      const model = BootScreenModel(
        screenType: BootScreenType.simpleLoading,
        message: 'Chargement',
        reasonCode: 'technical_startup',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
      );
      final primary = FocusNode();
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _wrap(
          BootScreenRenderer(model: model, primaryActionFocusNode: primary),
        ),
      );

      expect(find.byType(BootSimpleLoadingScreen), findsOneWidget);
      expect(find.byType(BootRecoveryPanel), findsNothing);
      expect(find.byType(AnimatedSwitcher), findsNWidgets(2));
    });

    testWidgets('anime les changements entre surfaces de boot', (tester) async {
      const loadingModel = BootScreenModel(
        screenType: BootScreenType.simpleLoading,
        message: 'Chargement',
        reasonCode: 'technical_startup',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
      );
      const recoveryModel = BootScreenModel(
        screenType: BootScreenType.actionRequired,
        title: 'Action requise',
        message: 'Connectez-vous',
        reasonCode: 'auth_required',
        isInteractive: true,
        initialFocus: BootFocusTarget.primaryAction,
        severity: BootScreenSeverity.warning,
        showLogo: true,
        showProgress: false,
        primaryAction: BootActionIntent.login,
        primaryActionLabel: 'Se connecter',
      );
      final primary = FocusNode();
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _wrap(
          BootScreenRenderer(
            model: loadingModel,
            primaryActionFocusNode: primary,
          ),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BootScreenRenderer(
            model: recoveryModel,
            primaryActionFocusNode: primary,
            onAction: (_) {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 110));

      expect(find.byType(BootSimpleLoadingScreen), findsOneWidget);
      expect(find.byType(BootRecoveryPanel), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(BootSimpleLoadingScreen), findsNothing);
      expect(find.byType(BootRecoveryPanel), findsOneWidget);
    });

    testWidgets('rend le recovery si le modele est interactif', (tester) async {
      const model = BootScreenModel(
        screenType: BootScreenType.actionRequired,
        title: 'Action requise',
        message: 'Connectez-vous',
        reasonCode: 'auth_required',
        isInteractive: true,
        initialFocus: BootFocusTarget.primaryAction,
        severity: BootScreenSeverity.warning,
        showLogo: true,
        showProgress: false,
        primaryAction: BootActionIntent.login,
        primaryActionLabel: 'Se connecter',
      );
      final primary = FocusNode();
      addTearDown(primary.dispose);
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          BootScreenRenderer(
            model: model,
            primaryActionFocusNode: primary,
            onAction: (_) => tapped = true,
          ),
        ),
      );

      expect(find.byType(BootRecoveryPanel), findsOneWidget);
      expect(find.byType(BootSimpleLoadingScreen), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('forceRecovery prend le dessus sur un etat non interactif', (
      tester,
    ) async {
      const model = BootScreenModel(
        screenType: BootScreenType.catalogLoading,
        message: 'Preparation du catalogue',
        reasonCode: 'catalog_preparing',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
      );
      final primary = FocusNode();
      addTearDown(primary.dispose);

      await tester.pumpWidget(
        _wrap(
          BootScreenRenderer(
            model: model,
            forceRecovery: true,
            primaryActionFocusNode: primary,
            onAction: (_) {},
          ),
        ),
      );

      expect(find.byType(BootRecoveryPanel), findsOneWidget);
      expect(find.byType(BootCatalogLoadingScreen), findsNothing);
    });
  });
}
