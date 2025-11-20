import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/person/presentation/widgets/person_biography_section.dart';

void main() {
  group('PersonBiographySection', () {
    testWidgets('renders title and expand/collapse control', (tester) async {
      const longText =
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
          'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
          'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
          'nisi ut aliquip ex ea commodo consequat.';

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: PersonBiographySection(biography: longText),
            ),
          ),
        ),
      );

      // Title is localized
      expect(find.text('Biographie'), findsOneWidget);

      // Initially shows expand action (collapsed state)
      expect(find.text('Agrandir'), findsOneWidget);
      expect(find.text('Rétrécir'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Agrandir'));
      await tester.pumpAndSettle();

      // Now shows collapse action
      expect(find.text('Rétrécir'), findsOneWidget);
      expect(find.text('Agrandir'), findsNothing);
    });
  });
}