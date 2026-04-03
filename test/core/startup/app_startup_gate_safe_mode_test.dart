import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/app_startup_gate.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/startup/domain/startup_contracts.dart';

void main() {
  testWidgets('shows SafeMode screen when startup result is safeMode', (
    tester,
  ) async {
    final fake = StartupResult.safeMode(
      durationMs: 1,
      failure: StartupFailure(
        code: StartupFailureCode.dependenciesInitFailed,
        phase: StartupPhase.initDependencies,
        message: 'deps failed',
        original: StateError('x'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          app_startup_provider.appStartupProvider.overrideWith(
            (ref) async => fake,
          ),
        ],
        child: const AppStartupGate(child: MaterialApp(home: Text('OK'))),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('OK'), findsNothing);
    expect(find.textContaining('SafeMode'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.textContaining(
        'reasonCode=startup_dependencies_init_failed',
      ),
      findsOneWidget,
    );
    // In tests, `kReleaseMode` is false, so detailed info is shown.
    expect(find.textContaining('phase='), findsOneWidget);
  });
}

