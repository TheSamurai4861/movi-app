import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/subscription/data/catalog/subscription_product_catalog.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';

void main() {
  group('SubscriptionProductCatalog', () {
    test('builds active entitlements when a product is active', () {
      final catalog = SubscriptionProductCatalog();

      final entitlements = catalog.buildEntitlements({'movi_premium_monthly'});

      expect(entitlements, hasLength(PremiumFeature.values.length));
      expect(entitlements.every((e) => e.isActive), isTrue);
    });

    test('returns null active plan when no product is active', () {
      final catalog = SubscriptionProductCatalog();

      final activePlan = catalog.activePlanIdFromProductIds({});

      expect(activePlan, isNull);
    });

    test('resolves active plan id from store product ids', () {
      final catalog = SubscriptionProductCatalog();

      final activePlan = catalog.activePlanIdFromProductIds(
        {'movi_premium_annual'},
      );

      expect(activePlan, 'movi_premium_annual');
    });
  });
}

