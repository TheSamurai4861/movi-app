import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/subscription/presentation/widgets/premium_feature_gate.dart';

void main() {
  testWidgets('PremiumFeatureGate renders lockedBuilder when not premium', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        canAccessPremiumFeatureProvider.overrideWith(
          (ref, feature) async => false,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PremiumFeatureGate(
            feature: PremiumFeature.localProfiles,
            lockedBuilder: (_) => const Text('locked'),
            unlockedBuilder: (_) => const Text('unlocked'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('locked'), findsOneWidget);
    expect(find.text('unlocked'), findsNothing);
  });

  testWidgets('PremiumFeatureGate renders unlockedBuilder when premium', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        canAccessPremiumFeatureProvider.overrideWith(
          (ref, feature) async => true,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PremiumFeatureGate(
            feature: PremiumFeature.localProfiles,
            lockedBuilder: (_) => const Text('locked'),
            unlockedBuilder: (_) => const Text('unlocked'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('unlocked'), findsOneWidget);
    expect(find.text('locked'), findsNothing);
  });
}

