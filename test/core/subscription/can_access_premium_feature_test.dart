import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

void main() {
  test('CanAccessPremiumFeature delegates to snapshot entitlement', () async {
    final repo = _FakeSubscriptionRepository(
      snapshot: SubscriptionSnapshot(
        status: SubscriptionStatus.active,
        billingAvailability: BillingAvailability.available,
        activePlanId: 'movi_premium_monthly',
        entitlements: PremiumFeature.values
            .map(
              (feature) => SubscriptionEntitlement(
                feature: feature,
                isActive: feature == PremiumFeature.localProfiles,
              ),
            )
            .toList(growable: false),
      ),
    );
    final useCase = CanAccessPremiumFeature(repo);

    expect(await useCase(PremiumFeature.localProfiles), isTrue);
    expect(await useCase(PremiumFeature.cloudLibrarySync), isFalse);
  });
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required this.snapshot});

  final SubscriptionSnapshot snapshot;

  @override
  Future<SubscriptionSnapshot> getCurrentSubscription() async => snapshot;

  @override
  Future<List<SubscriptionOffer>> loadAvailableOffers() {
    throw UnimplementedError();
  }

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

