import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/reporting/presentation/widgets/report_problem_sheet.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  testWidgets('report problem sheet renders', (tester) async {
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
    expect(find.byType(ReportProblemSheet), findsOneWidget);
  });
}
