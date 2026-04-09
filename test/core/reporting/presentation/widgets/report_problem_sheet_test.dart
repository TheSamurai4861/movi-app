import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/reporting/presentation/widgets/report_problem_sheet.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  testWidgets('focus starts on input and enter moves to submit', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: ReportProblemSheet(
              contentType: ContentType.movie,
              tmdbId: 42,
              contentTitle: 'Test',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('ReportProblemMessageInput'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('ReportProblemSubmitButton'),
    );
  });
}
