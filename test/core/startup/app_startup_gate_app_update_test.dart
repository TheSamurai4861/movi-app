import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/app_update/presentation/providers/app_update_provider.dart'
    as app_update_provider;
import 'package:movi/src/core/app_update/presentation/widgets/app_update_blocked_screen.dart';
import 'package:movi/src/core/startup/app_startup_gate.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/startup/domain/startup_contracts.dart';

void main() {
  const readyApp = MaterialApp(home: Scaffold(body: Text('APP READY')));

  testWidgets('shows blocked screen when app update decision is blocking', (
    tester,
  ) async {
    final ready = StartupResult.ready(durationMs: 1);
    final blockingDecision = AppUpdateDecision.forceUpdate(
      currentVersion: '1.0.1',
      platform: 'android',
      checkedAt: DateTime.utc(2026, 4, 10, 12),
      reasonCode: 'app_update_check_unavailable_blocked',
      message: 'Connexion requise pour verifier la validite de cette version.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          app_startup_provider.appStartupProvider.overrideWith(
            (ref) async => ready,
          ),
          app_update_provider.appUpdateDecisionProvider.overrideWith(
            (ref) async => blockingDecision,
          ),
        ],
        child: const AppStartupGate(child: readyApp),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('APP READY'), findsNothing);
    expect(find.byType(AppUpdateBlockedScreen), findsOneWidget);
  });

  testWidgets('renders child when app update decision is allowed', (
    tester,
  ) async {
    final ready = StartupResult.ready(durationMs: 1);
    final allowedDecision = AppUpdateDecision.allow(
      currentVersion: '1.0.2',
      platform: 'android',
      checkedAt: DateTime.utc(2026, 4, 10, 12),
      reasonCode: 'app_update_allowed',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          app_startup_provider.appStartupProvider.overrideWith(
            (ref) async => ready,
          ),
          app_update_provider.appUpdateDecisionProvider.overrideWith(
            (ref) async => allowedDecision,
          ),
        ],
        child: const AppStartupGate(child: readyApp),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppUpdateBlockedScreen), findsNothing);
    expect(find.text('APP READY'), findsOneWidget);
  });
}
