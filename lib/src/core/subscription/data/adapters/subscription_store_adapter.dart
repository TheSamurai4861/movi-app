import 'package:movi/src/core/subscription/data/adapters/store_product_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';

abstract class SubscriptionStoreAdapter {
  Future<BillingAvailability> getBillingAvailability();

  Future<List<StoreProductOffer>> loadOffers(Set<String> productIds);

  Future<Set<String>> purchase(String productId);

  Future<Set<String>> restore();
}
