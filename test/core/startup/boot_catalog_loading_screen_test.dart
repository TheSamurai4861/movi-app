import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/presentation/widgets/boot_catalog_loading_screen.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';

void main() {
  testWidgets('catalog: logo, message, pas de bouton', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BootCatalogLoadingScreen(
              message: 'Chargement des films et series',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MoviAssetIcon), findsOneWidget);
    expect(find.textContaining('Chargement des films'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('catalog: sous-message secondaire optionnel', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BootCatalogLoadingScreen(
              message: 'Preparation',
              secondaryMessage: 'Cache local pret',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Cache local pret'), findsOneWidget);
  });

  testWidgets('viewport 393x852 et textes longs sans exception', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;

    final long = List<String>.filled(35, 'w').join(' ');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BootCatalogLoadingScreen(
              message: long,
              secondaryMessage: long,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
