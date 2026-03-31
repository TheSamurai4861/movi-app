import 'package:movi/src/core/subscription/data/adapters/store_product_offer.dart';
import 'package:movi/src/core/subscription/data/adapters/subscription_store_adapter.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';

class UnsupportedSubscriptionStoreAdapter implements SubscriptionStoreAdapter {
  const UnsupportedSubscriptionStoreAdapter();

  @override
  Future<BillingAvailability> getBillingAvailability() async {
    return BillingAvailability.unavailable;
  }

  @override
  Future<List<StoreProductOffer>> loadOffers(Set<String> productIds) async {
    return const <StoreProductOffer>[];
  }

  @override
  Future<Set<String>> purchase(String productId) async {
    throw SubscriptionFailure.billingUnavailable();
  }

  @override
  Future<Set<String>> restore() async {
    throw SubscriptionFailure.providerNotConfigured();
  }
}
