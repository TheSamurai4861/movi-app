import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_responsive_logo.dart';
import 'package:movi/src/features/tv/presentation/pages/tv_detail_page.dart';

void main() {
  testWidgets('buildTvDetailMobileHeroLogo uses MoviResponsiveLogo for SVG logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildTvDetailMobileHeroLogo(
            mediaTitle: 'Demo Series',
            titleStyle: const TextStyle(fontSize: 28),
            maxWidth: 300,
            logo: Uri.parse('https://image.tmdb.org/t/p/original/demo_logo.svg'),
          ),
        ),
      ),
    );

    expect(find.byType(MoviResponsiveLogo), findsOneWidget);
    expect(find.text('Demo Series'), findsNothing);
  });

  testWidgets('buildTvDetailMobileHeroLogo falls back to title when logo is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildTvDetailMobileHeroLogo(
            mediaTitle: 'Demo Series',
            titleStyle: const TextStyle(fontSize: 28),
            maxWidth: 300,
          ),
        ),
      ),
    );

    expect(find.byType(MoviResponsiveLogo), findsNothing);
    expect(find.text('Demo Series'), findsOneWidget);
  });
}

