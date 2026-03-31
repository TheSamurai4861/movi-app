import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/subscription/presentation/widgets/premium_feature_gate.dart';

void main() {
  testWidgets('PremiumFeatureGate renders lockedBuilder when not premium', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.inactive,
                billingAvailability: BillingAvailability.available,
                entitlements: const [],
              ),
            ),
          ),
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
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.active,
                billingAvailability: BillingAvailability.available,
                entitlements: const [
                  SubscriptionEntitlement(
                    feature: PremiumFeature.localProfiles,
                    isActive: true,
                  ),
                ],
              ),
            ),
          ),
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

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required this.snapshot});

  final SubscriptionSnapshot snapshot;

  @override
  Future<SubscriptionSnapshot> getCurrentSubscription() async => snapshot;

  @override
  Future<List<SubscriptionOffer>> loadAvailableOffers() async => const [];

  @override
  Future<SubscriptionSnapshot> purchaseSubscription({required String offerId}) {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> refreshSubscription() {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> restoreSubscription() {
    throw UnimplementedError();
  }
}

