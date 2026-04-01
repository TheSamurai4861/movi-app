import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/features/welcome/presentation/pages/splash_bootstrap_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows progress message during preloadCompleteHome', (
    tester,
  ) async {
    // Arrange: launch state says we're in preload.
    final launchState = const AppLaunchState(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.preloadCompleteHome,
      error: null,
    );

    final container = ProviderContainer(
      overrides: [
        appLaunchOrchestratorProvider.overrideWith(
          () => _FakeLaunchOrchestrator(launchState),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Act: stage = loadingCategories should map to overlayLoadingCategories.
    container
        .read(homeBootstrapProgressStageProvider.notifier)
        .set(HomeBootstrapProgressStage.loadingCategories);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashBootstrapPage(),
        ),
      ),
    );
    // OverlaySplash has a periodic timer (elapsed seconds), so it never "settles".
    await tester.pump(const Duration(milliseconds: 50));

    // Assert: should show the translated message.
    final context = tester.element(find.byType(SplashBootstrapPage));
    final l10n = AppLocalizations.of(context)!;
    expect(find.textContaining(l10n.overlayLoadingCategories), findsOneWidget);
  });

  testWidgets('shows recovery message suffix when retrying', (tester) async {
    final launchState = const AppLaunchState(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.preloadCompleteHome,
      error: null,
      recoveryMessage: 'Recovery: iptv_preload (2/3)',
    );

    final container = ProviderContainer(
      overrides: [
        appLaunchOrchestratorProvider.overrideWith(
          () => _FakeLaunchOrchestrator(launchState),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(homeBootstrapProgressStageProvider.notifier)
        .set(HomeBootstrapProgressStage.loadingCategories);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashBootstrapPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Recovery: iptv_preload (2/3)'), findsOneWidget);
  });

  testWidgets('keeps overlay visible while preload is still running', (
    tester,
  ) async {
    final launchState = const AppLaunchState(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.preloadCompleteHome,
      error: null,
    );

    final container = ProviderContainer(
      overrides: [
        appLaunchOrchestratorProvider.overrideWith(
          () => _FakeLaunchOrchestrator(launchState),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(homeBootstrapProgressStageProvider.notifier)
        .set(HomeBootstrapProgressStage.loadingCategories);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashBootstrapPage(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SplashBootstrapPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Recovery:'), findsNothing);
  });
}

class _FakeLaunchOrchestrator extends AppLaunchOrchestrator {
  _FakeLaunchOrchestrator(this._state);
  final AppLaunchState _state;

  @override
  AppLaunchState build() => _state;
}
