import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final context = tester.element(find.byType(CreateProfileDialog));
    final l10n = AppLocalizations.of(context)!;
    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, l10n.actionConfirm),
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
      l10n.profilePinSetLabel,
    );
    await tester.ensureVisible(pinButton.first);
    await tester.tap(pinButton.first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '1234');
    final dialogConfirmButton = find.widgetWithText(
      ElevatedButton,
      l10n.actionConfirm,
    );
    await tester.ensureVisible(dialogConfirmButton.last);
    await tester.tap(dialogConfirmButton.last);
    await tester.pumpAndSettle();

    expect(find.text(l10n.profilePinEditLabel), findsOneWidget);
    expect(find.text(l10n.profilePinSaved), findsOneWidget);
  });

  testWidgets('does not close dialog when pressing backspace in name field', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    final nameField = find.byType(TextField).first;
    await tester.tap(nameField);
    await tester.pumpAndSettle();

    await tester.enterText(nameField, 'Alex');
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(find.byType(CreateProfileDialog), findsOneWidget);
    expect(tester.widget<TextField>(nameField).controller!.text, 'Ale');
  });
}
