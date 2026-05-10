import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/home/presentation/widgets/home_error_banner.dart';

void main() {
  testWidgets('exposes the primary Home retry action', (tester) async {
    RecoveryAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeErrorBanner(
            notice: const HomeDegradationNotice(
              reasonCodes: <String>[StartupRecoveryReasonCodes.homeFeedFailed],
              actions: <RecoveryAction>[RecoveryAction.retryHomeSections],
            ),
            onAction: (action) => selectedAction = action,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Recharger'));
    await tester.pump();

    expect(selectedAction, RecoveryAction.retryHomeSections);
  });

  testWidgets('keeps banner actions focusable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeErrorBanner(
            notice: const HomeDegradationNotice(
              reasonCodes: <String>[
                StartupRecoveryReasonCodes.homeIptvSectionsEmpty,
              ],
              actions: <RecoveryAction>[
                RecoveryAction.retryHomeSections,
                RecoveryAction.resyncSource,
              ],
            ),
            onAction: (_) {},
          ),
        ),
      ),
    );

    final primary = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Recharger'),
    );
    final secondary = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Resynchroniser'),
    );

    expect(primary.onPressed, isNotNull);
    expect(secondary.onPressed, isNotNull);
  });

  testWidgets('prioritizes Home sections when multiple actions exist', (
    tester,
  ) async {
    final selectedActions = <RecoveryAction>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeErrorBanner(
            notice: const HomeDegradationNotice(
              reasonCodes: <String>[StartupRecoveryReasonCodes.homePartial],
              actions: <RecoveryAction>[
                RecoveryAction.retryLibrary,
                RecoveryAction.retryHomeSections,
              ],
            ),
            onAction: selectedActions.add,
          ),
        ),
      ),
    );

    expect(
      find.text("Certaines sections n'ont pas pu etre chargees."),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Recharger'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Recharger la reprise'));
    await tester.pump();

    expect(selectedActions, <RecoveryAction>[
      RecoveryAction.retryHomeSections,
      RecoveryAction.retryLibrary,
    ]);
  });
}
