import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart';

void main() {
  Widget buildHarness(Profile profile) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ManageProfileDialog(profile: profile)),
      ),
    );
  }

  testWidgets('allows enabling child profile without a PIN', (tester) async {
    const profile = Profile(
      id: 'profile-1',
      accountId: 'account-1',
      name: 'Alex',
      color: 0xFF2160AB,
    );

    await tester.pumpWidget(buildHarness(profile));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final confirmButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirm'),
    );

    expect(confirmButton.onPressed, isNotNull);
    expect(
      find.text(
        'Définissez un code PIN avant de repasser ce profil en adulte.',
      ),
      findsNothing,
    );
  });

  testWidgets(
    'disables save when switching a child profile to adult without a PIN',
    (tester) async {
      const profile = Profile(
        id: 'profile-3',
        accountId: 'account-1',
        name: 'Alex',
        color: 0xFF2160AB,
        isKid: true,
        pegiLimit: 12,
      );

      await tester.pumpWidget(buildHarness(profile));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final confirmButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );

      expect(confirmButton.onPressed, isNull);
      expect(
        find.text(
          'Définissez un code PIN avant de repasser ce profil en adulte.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('disables PIN removal while the profile is still a child profile', (
    tester,
  ) async {
    const profile = Profile(
      id: 'profile-2',
      accountId: 'account-1',
      name: 'Sam',
      color: 0xFF2160AB,
      isKid: true,
      pegiLimit: 12,
      hasPin: true,
    );

    await tester.pumpWidget(buildHarness(profile));
    await tester.pumpAndSettle();

    final removePinButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Supprimer le code PIN'),
    );

    expect(removePinButton.onPressed, isNull);
    expect(
      find.text(
        'Pour supprimer le code PIN, désactivez d’abord le profil enfant puis enregistrez.',
      ),
      findsOneWidget,
    );
  });
}
