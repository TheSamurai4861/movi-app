import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/theme/app_theme.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'uses the theme accent when accent preferences are not registered yet',
    (tester) async {
      const accentColor = Color(0xFF9C27B0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(accentColor: accentColor),
            home: const Scaffold(
              body: OverlaySplash(showProgressDetails: false),
            ),
          ),
        ),
      );

      final logo = tester.widget<MoviAssetIcon>(find.byType(MoviAssetIcon));
      expect(logo.color, accentColor);
    },
  );
}
