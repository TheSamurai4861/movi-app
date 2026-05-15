import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_localizer.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_catalog_loading_screen.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_recovery_panel.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/home/presentation/widgets/home_error_banner.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

/// Aligne le corps de surface sur la logique d’affichage du splash bootstrap
/// (chargements vs panneau recovery), pour des tests widget sans Riverpod
/// orchestrateur complet.
Widget buildBootSurfaceForModel(
  BootScreenModel model, {
  required FocusNode primaryFocus,
  FocusNode? secondaryFocus,
  void Function(BootActionIntent intent)? onAction,
}) {
  final localized = localizeBootScreenModel(
    model: model,
    l10n: lookupAppLocalizations(const Locale('fr')),
  );

  switch (localized.screenType) {
    case BootScreenType.catalogLoading:
      return BootCatalogLoadingScreen(
        message: localized.message,
        secondaryMessage: localized.secondaryMessage,
        showLogo: localized.showLogo,
        showProgress: localized.showProgress,
      );
    case BootScreenType.simpleLoading:
    case BootScreenType.openingHome:
      return BootSimpleLoadingScreen.forBootModel(localized);
    case BootScreenType.actionRequired:
    case BootScreenType.technicalFailure:
    case BootScreenType.recovery:
      return BootRecoveryPanel.fromBootModel(
        model: localized,
        onAction: onAction ?? (_) {},
        primaryFocusNode: primaryFocus,
        secondaryFocusNode: secondaryFocus,
      );
    case BootScreenType.homePartialNotice:
      return BootSimpleLoadingScreen(
        message: localized.message,
        showLogo: localized.showLogo,
        showProgress: localized.showProgress,
      );
  }
}

void _expectNoReasonCodeLeak(BootScreenModel model, WidgetTester tester) {
  expect(
    find.text(model.reasonCode),
    findsNothing,
    reason: 'Le reasonCode ne doit pas être affiché tel quel',
  );
}

void _expectNoRawTechnicalDetailsLeak(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join('\n');
  expect(
    texts,
    isNot(contains('http://')),
    reason: 'Aucun endpoint brut ne doit etre affiche a l utilisateur',
  );
  expect(
    texts,
    isNot(contains('https://')),
    reason: 'Aucune URL brute ne doit etre affichee a l utilisateur',
  );
  expect(
    texts,
    isNot(contains('local_xtream_account_')),
    reason: 'Aucun identifiant interne de source ne doit etre visible',
  );
}

Widget _material(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  const mapper = BootScreenMapper();

  group('chargements non interactifs', () {
    testWidgets('idle -> simple loading : logo, pas de CTA', (tester) async {
      final model = mapper.fromLaunchState(const AppLaunchState());
      expect(model.isInteractive, isFalse);

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: FocusNode())),
      );
      await tester.pump();

      expect(find.byType(MoviAssetIcon), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      _expectNoReasonCodeLeak(model, tester);
    });

    testWidgets('preload catalogue : logo, pas de CTA', (tester) async {
      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.running,
          phase: AppLaunchPhase.preloadCompleteHome,
        ),
      );
      expect(model.isInteractive, isFalse);

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: FocusNode())),
      );
      await tester.pump();

      expect(find.byType(MoviAssetIcon), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      _expectNoReasonCodeLeak(model, tester);
    });
  });

  group('recovery source (mapper -> panneau)', () {
    testWidgets('timeout sync : primaire + secondaire, pas de reasonCode', (
      tester,
    ) async {
      final primary = FocusNode();
      final secondary = FocusNode();
      addTearDown(primary.dispose);
      addTearDown(secondary.dispose);

      final model = mapper.fromLaunchState(
        AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeSources,
          recoveryPlan: StartupRecoveryPlan(
            reasonCode: StartupRecoveryReasonCodes.catalogSyncTimeout,
            actions: <RecoveryAction>[
              RecoveryAction.retry,
              RecoveryAction.chooseSource,
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        _material(
          buildBootSurfaceForModel(
            model,
            primaryFocus: primary,
            secondaryFocus: secondary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Réessayer'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Changer de source'),
        findsOneWidget,
      );
      _expectNoReasonCodeLeak(model, tester);
      _expectNoRawTechnicalDetailsLeak(tester);
    });

    testWidgets('credentials invalides : primaire seulement', (tester) async {
      final primary = FocusNode();
      addTearDown(primary.dispose);

      final model = mapper.fromLaunchState(
        AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeSources,
          recoveryPlan: StartupRecoveryPlan(
            reasonCode: StartupRecoveryReasonCodes.catalogCredentialsInvalid,
            actions: <RecoveryAction>[RecoveryAction.reconnectSource],
          ),
        ),
      );

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: primary)),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Reconnecter la source'),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsNothing);
      _expectNoReasonCodeLeak(model, tester);
    });

    testWidgets('catalogue vide : resynchroniser + changer de source', (
      tester,
    ) async {
      final primary = FocusNode();
      final secondary = FocusNode();
      addTearDown(primary.dispose);
      addTearDown(secondary.dispose);

      final model = mapper.fromLaunchState(
        AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeSources,
          recoveryPlan: StartupRecoveryPlan(
            reasonCode: StartupRecoveryReasonCodes.catalogEmpty,
            actions: <RecoveryAction>[
              RecoveryAction.resyncSource,
              RecoveryAction.chooseSource,
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        _material(
          buildBootSurfaceForModel(
            model,
            primaryFocus: primary,
            secondaryFocus: secondary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Resynchroniser'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, 'Changer de source'),
        findsOneWidget,
      );
      _expectNoReasonCodeLeak(model, tester);
    });
  });

  group('destinations action requise', () {
    testWidgets('auth / credentials flow -> Se connecter', (tester) async {
      final primary = FocusNode();
      addTearDown(primary.dispose);

      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.auth,
        ),
      );

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: primary)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Se connecter'), findsOneWidget);
      _expectNoReasonCodeLeak(model, tester);
    });

    testWidgets('profil requis -> Continuer', (tester) async {
      final primary = FocusNode();
      addTearDown(primary.dispose);

      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeUser,
        ),
      );

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: primary)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Continuer'), findsOneWidget);
      expect(find.textContaining('Profil'), findsWidgets);
      _expectNoReasonCodeLeak(model, tester);
    });

    testWidgets('source requise sans plan -> Ajouter une source', (
      tester,
    ) async {
      final primary = FocusNode();
      addTearDown(primary.dispose);

      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.welcomeSources,
        ),
      );

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: primary)),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Ajouter une source'),
        findsOneWidget,
      );
      _expectNoReasonCodeLeak(model, tester);
    });

    testWidgets('selection source -> Changer de source', (tester) async {
      final primary = FocusNode();
      addTearDown(primary.dispose);

      final model = mapper.fromLaunchState(
        const AppLaunchState(
          status: AppLaunchStatus.success,
          destination: BootstrapDestination.chooseSource,
        ),
      );

      await tester.pumpWidget(
        _material(buildBootSurfaceForModel(model, primaryFocus: primary)),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Changer de source'),
        findsOneWidget,
      );
      _expectNoReasonCodeLeak(model, tester);
    });
  });

  group('technical failure', () {
    testWidgets('echec technique : Réessayer + Exporter, focus primaire', (
      tester,
    ) async {
      final primary = FocusNode();
      final secondary = FocusNode();
      addTearDown(primary.dispose);
      addTearDown(secondary.dispose);

      final model = mapper.fromLaunchState(
        const AppLaunchState(status: AppLaunchStatus.failure),
      );

      await tester.pumpWidget(
        _material(
          buildBootSurfaceForModel(
            model,
            primaryFocus: primary,
            secondaryFocus: secondary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Réessayer'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Exporter les logs'),
        findsOneWidget,
      );
      expect(primary.hasFocus, isTrue);
      _expectNoReasonCodeLeak(model, tester);
      _expectNoRawTechnicalDetailsLeak(tester);
    });
  });

  group('Home partiel (banniere)', () {
    testWidgets('degradation feed : message l10n + action primaire', (
      tester,
    ) async {
      await tester.pumpWidget(
        _material(
          HomeErrorBanner(
            notice: const HomeDegradationNotice(
              reasonCodes: <String>[StartupRecoveryReasonCodes.homeFeedFailed],
              actions: <RecoveryAction>[RecoveryAction.retryHomeSections],
            ),
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('sections'), findsWidgets);
      expect(find.byType(MoviAssetIcon), findsNothing);
      expect(
        find.widgetWithText(FilledButton, 'Reload sections'),
        findsOneWidget,
      );
      expect(
        find.text(StartupRecoveryReasonCodes.homeFeedFailed),
        findsNothing,
      );
    });
  });
}
