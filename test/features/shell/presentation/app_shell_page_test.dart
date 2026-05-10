import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/state/device_capabilities_provider.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_large_layout.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_tv_layout.dart';
import 'package:movi/src/features/shell/presentation/pages/app_shell_page.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

void main() {
  List<WidgetBuilder> testPageBuilders() {
    return List<WidgetBuilder>.generate(
      4,
      (index) =>
          (_) => ColoredBox(
            color: Colors.primaries[index],
            child: Text('page-$index', textDirection: TextDirection.ltr),
          ),
    );
  }

  Widget buildShell({required bool isTelevisionDevice}) {
    return ProviderScope(
      overrides: [
        isTelevisionDeviceProvider.overrideWith((ref) => isTelevisionDevice),
        selectedIndexProvider.overrideWith((ref) => 0),
        keepAliveIndicesProvider.overrideWith((ref) => const <int>{0}),
        appLaunchStateProvider.overrideWith((ref) => const AppLaunchState()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShellPage(pageBuildersOverride: testPageBuilders()),
      ),
    );
  }

  testWidgets(
    'renders TV shell layout for a native television device',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildShell(isTelevisionDevice: true));
      await tester.pumpAndSettle();

      expect(find.byType(AppShellTvLayout), findsOneWidget);
      expect(find.byType(AppShellLargeLayout), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'does not render TV shell layout for a non-TV Android tablet',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildShell(isTelevisionDevice: false));
      await tester.pumpAndSettle();

      expect(find.byType(AppShellTvLayout), findsNothing);
      expect(find.byType(AppShellLargeLayout), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'focuses the sidebar on TV layout mount',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildShell(isTelevisionDevice: true));
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'SidebarNavItem-0',
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
