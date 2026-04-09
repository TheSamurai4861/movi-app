import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/create_profile_dialog.dart';

void main() {
  Widget buildHarness() {
    return const ProviderScope(
      child: MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CreateProfileDialog()),
      ),
    );
  }

  testWidgets('allows confirmation when child profile has no PIN', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Alex');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Valider'),
    );

    expect(confirmButton.onPressed, isNotNull);
  });

  testWidgets('shows confirmation feedback after defining a PIN', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CreateProfileDialog));
    final l10n = AppLocalizations.of(context)!;

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final pinButton = find.widgetWithText(
      ElevatedButton,
      l10n.hc_definir_code_pin_53a0bd07,
    );
    await tester.ensureVisible(pinButton.first);
    await tester.tap(pinButton.first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '1234');
    final dialogConfirmButton = find.widgetWithText(ElevatedButton, 'Valider');
    await tester.ensureVisible(dialogConfirmButton.last);
    await tester.tap(dialogConfirmButton.last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.profilePinEditLabel), findsOneWidget);
    expect(find.text(l10n.profilePinSaved), findsOneWidget);
  });
}
