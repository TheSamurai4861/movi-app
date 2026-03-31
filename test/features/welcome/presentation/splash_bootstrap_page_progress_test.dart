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

  testWidgets('shows progress message during preloadMinimalHome', (tester) async {
    // Arrange: launch state says we're in preload.
    final launchState = const AppLaunchState(
      status: AppLaunchStatus.running,
      phase: AppLaunchPhase.preloadMinimalHome,
      error: null,
    );

    final container = ProviderContainer(
      overrides: [
        appLaunchOrchestratorProvider.overrideWith(() => _FakeLaunchOrchestrator(launchState)),
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
    expect(find.text('Loading categories…'), findsOneWidget);
  });
}

class _FakeLaunchOrchestrator extends AppLaunchOrchestrator {
  _FakeLaunchOrchestrator(this._state);
  final AppLaunchState _state;

  @override
  AppLaunchState build() => _state;
}

