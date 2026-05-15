import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/config/models/feature_flags.dart';
import 'package:movi/src/core/config/providers/config_provider.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/presentation/widgets/home_page_loading_overlay.dart';

void main() {
  test('homeHeroMetaLoadingProvider toggles without side effects', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(hp.homeHeroMetaLoadingProvider), isFalse);
    container.read(hp.homeHeroMetaLoadingProvider.notifier).set(true);
    expect(container.read(hp.homeHeroMetaLoadingProvider), isTrue);
    container.read(hp.homeHeroMetaLoadingProvider.notifier).set(true);
    expect(container.read(hp.homeHeroMetaLoadingProvider), isTrue);
  });

  testWidgets('HomePageLoadingOverlay reacts only to hero meta flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hp.homeControllerProvider.overrideWith(_IdleHomeController.new),
          featureFlagsProvider.overrideWithValue(const FeatureFlags()),
        ],
        child: const MaterialApp(home: HomePageLoadingOverlay()),
      ),
    );

    expect(find.byType(OverlaySplash), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePageLoadingOverlay)),
    );
    container.read(hp.homeHeroMetaLoadingProvider.notifier).set(true);
    await tester.pump();

    expect(find.byType(OverlaySplash), findsOneWidget);
  });
}

class _IdleHomeController extends hp.HomeController {
  @override
  hp.HomeState build() => const hp.HomeState(isLoading: false);
}
