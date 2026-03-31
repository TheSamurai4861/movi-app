import 'package:movi/src/core/subscription/data/adapters/store_product_offer.dart';
import 'package:movi/src/core/subscription/data/adapters/subscription_store_adapter.dart';
import 'package:movi/src/core/subscription/data/catalog/subscription_product_catalog.dart';
import 'package:movi/src/core/subscription/data/datasources/subscription_local_cache_data_source.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class StoreSubscriptionRepository implements SubscriptionRepository {
  StoreSubscriptionRepository({
    required SubscriptionLocalCacheDataSource localCache,
    required SubscriptionStoreAdapter storeAdapter,
    required SubscriptionProductCatalog productCatalog,
  }) : _localCache = localCache,
       _storeAdapter = storeAdapter,
       _productCatalog = productCatalog;

  final SubscriptionLocalCacheDataSource _localCache;
  final SubscriptionStoreAdapter _storeAdapter;
  final SubscriptionProductCatalog _productCatalog;

  @override
  Future<SubscriptionSnapshot> getCurrentSubscription() async {
    final cachedSnapshot = await _localCache.read();
    final billingAvailability = await _storeAdapter.getBillingAvailability();
    return cachedSnapshot.copyWith(billingAvailability: billingAvailability);
  }

  @override
  Future<List<SubscriptionOffer>> loadAvailableOffers() async {
    final billingAvailability = await _storeAdapter.getBillingAvailability();
    if (billingAvailability == BillingAvailability.unavailable) {
      return const <SubscriptionOffer>[];
    }

    final storeOffers = await _storeAdapter.loadOffers(
      _productCatalog.storeProductIds,
    );

    return _mapStoreOffers(storeOffers);
  }

  @override
  Future<SubscriptionSnapshot> purchaseSubscription({
    required String offerId,
  }) async {
    final billingAvailability = await _storeAdapter.getBillingAvailability();
    if (billingAvailability != BillingAvailability.available) {
      throw SubscriptionFailure.billingUnavailable();
    }

    final storeProductId = _productCatalog.storeProductIdForOffer(offerId);
    final activeProductIds = await _storeAdapter.purchase(storeProductId);
    final snapshot = _buildSnapshot(
      activeProductIds: activeProductIds,
      billingAvailability: billingAvailability,
    );

    await _localCache.write(snapshot);
    return snapshot;
  }

  @override
  Future<SubscriptionSnapshot> restoreSubscription() async {
    final billingAvailability = await _storeAdapter.getBillingAvailability();
    if (billingAvailability == BillingAvailability.unavailable) {
      throw SubscriptionFailure.providerNotConfigured();
    }

    final activeProductIds = await _storeAdapter.restore();
    final snapshot = _buildSnapshot(
      activeProductIds: activeProductIds,
      billingAvailability: billingAvailability,
    );

    await _localCache.write(snapshot);
    return snapshot;
  }

  @override
  Future<SubscriptionSnapshot> refreshSubscription() async {
    final billingAvailability = await _storeAdapter.getBillingAvailability();
    if (billingAvailability == BillingAvailability.unavailable) {
      final cachedSnapshot = await _localCache.read();
      return cachedSnapshot.copyWith(billingAvailability: billingAvailability);
    }

    final activeProductIds = await _storeAdapter.restore();
    final snapshot = _buildSnapshot(
      activeProductIds: activeProductIds,
      billingAvailability: billingAvailability,
    );

    await _localCache.write(snapshot);
    return snapshot;
  }

  List<SubscriptionOffer> _mapStoreOffers(List<StoreProductOffer> storeOffers) {
    final offersByProductId = <String, StoreProductOffer>{
      for (final offer in storeOffers) offer.productId: offer,
    };

    return _productCatalog.offers
        .where((offer) => offersByProductId.containsKey(offer.storeProductId))
        .map((offer) {
          final storeOffer = offersByProductId[offer.storeProductId]!;
          return SubscriptionOffer(
            id: offer.offerId,
            storeProductId: offer.storeProductId,
            title: storeOffer.title,
            description: storeOffer.description,
            displayPrice: storeOffer.priceLabel,
          );
        })
        .toList(growable: false);
  }

  SubscriptionSnapshot _buildSnapshot({
    required Set<String> activeProductIds,
    required BillingAvailability billingAvailability,
  }) {
    final hasActiveSubscription = activeProductIds.isNotEmpty;

    return SubscriptionSnapshot(
      status: hasActiveSubscription
          ? SubscriptionStatus.active
          : SubscriptionStatus.inactive,
      billingAvailability: billingAvailability,
      entitlements: _productCatalog.buildEntitlements(activeProductIds),
      activePlanId: _productCatalog.activePlanIdFromProductIds(
        activeProductIds,
      ),
    );
  }
}
