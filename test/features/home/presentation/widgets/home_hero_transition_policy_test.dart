import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_transition_policy.dart';

void main() {
  group('HeroTransitionPolicy', () {
    testWidgets('television uses short background fade and instant overlay', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.binding.setSurfaceSize(const Size(1920, 1080));
        late HeroTransitionPolicy policy;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                policy = HeroTransitionPolicy.resolve(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(policy.backgroundFade, const Duration(milliseconds: 400));
        expect(policy.overlayFade, Duration.zero);
        expect(policy.mobileSizeAnimation, Duration.zero);
        expect(policy.enableStackedOverlayFades, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        await tester.binding.setSurfaceSize(null);
      }
    });

    testWidgets('mobile layout keeps standard overlay fades', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late HeroTransitionPolicy policy;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              policy = HeroTransitionPolicy.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(policy.overlayFade.inMilliseconds, greaterThan(0));
      expect(policy.enableStackedOverlayFades, isTrue);
    });

    testWidgets('respects disableAnimations', (tester) async {
      late HeroTransitionPolicy policy;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                policy = HeroTransitionPolicy.resolve(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(policy, HeroTransitionPolicy.reducedMotion);
    });
  });
}
