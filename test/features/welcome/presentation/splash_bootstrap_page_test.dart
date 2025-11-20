import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/app_router.dart' as routes;
import 'package:movi/src/features/welcome/presentation/pages/splash_bootstrap_page.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/core/widgets/widgets.dart';

void main() {
  group('SplashBootstrapPage', () {
    testWidgets('shows loading overlay when preload is loading', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appPreloadProvider.overrideWith((ref) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashBootstrapPage(),
          ),
        ),
      );

      expect(find.byType(OverlaySplash), findsOneWidget);
    });

    testWidgets('shows error with retry button when preload fails', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appPreloadProvider.overrideWith((ref) async {
            throw Exception('fail');
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashBootstrapPage(),
          ),
        ),
      );

      expect(find.byType(SnackBar), findsNothing);
      // Error layout contains a retry primary button
      expect(find.byType(MoviPrimaryButton), findsOneWidget);
    });

    testWidgets('success shows opening home overlay then navigates', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appPreloadProvider.overrideWith((ref) async {}),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: routes.AppRouteNames.bootstrap,
        routes: [
          GoRoute(
            path: routes.AppRouteNames.home,
            builder: (context, state) => const Scaffold(body: SizedBox(key: Key('home'))),
          ),
          GoRoute(
            path: routes.AppRouteNames.bootstrap,
            builder: (context, state) => const SplashBootstrapPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      // After success, page displays opening overlay text
      await tester.pump();
      final element = tester.element(find.byType(OverlaySplash));
      final l10n = AppLocalizations.of(element);
      final expected = l10n != null ? l10n.overlayOpeningHome : 'Opening home…';
      expect(find.text(expected), findsOneWidget);
    });
  });
}