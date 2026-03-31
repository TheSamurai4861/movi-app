import 'package:movi/src/core/subscription/data/catalog/subscription_offer_definition.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';

class SubscriptionProductCatalog {
  SubscriptionProductCatalog({List<SubscriptionOfferDefinition>? offers})
    : _offers = offers ?? _defaultOffers;

  final List<SubscriptionOfferDefinition> _offers;

  static const List<SubscriptionOfferDefinition> _defaultOffers =
      <SubscriptionOfferDefinition>[
        SubscriptionOfferDefinition(
          offerId: 'movi_premium_monthly',
          storeProductId: 'movi_premium_monthly',
          unlockedFeatures: PremiumFeature.values,
        ),
        SubscriptionOfferDefinition(
          offerId: 'movi_premium_annual',
          storeProductId: 'movi_premium_annual',
          unlockedFeatures: PremiumFeature.values,
        ),
      ];

  List<SubscriptionOfferDefinition> get offers =>
      List<SubscriptionOfferDefinition>.unmodifiable(_offers);

  Set<String> get storeProductIds =>
      _offers.map((offer) => offer.storeProductId).toSet();

  String storeProductIdForOffer(String offerId) {
    for (final offer in _offers) {
      if (offer.offerId == offerId) {
        return offer.storeProductId;
      }
    }
    throw SubscriptionFailure.offerNotFound(offerId);
  }

  String? activePlanIdFromProductIds(Set<String> activeProductIds) {
    for (final offer in _offers) {
      if (activeProductIds.contains(offer.storeProductId)) {
        return offer.offerId;
      }
    }
    return null;
  }

  List<SubscriptionEntitlement> buildEntitlements(
    Set<String> activeProductIds,
  ) {
    final activeFeatures = <PremiumFeature>{};

    for (final offer in _offers) {
      if (activeProductIds.contains(offer.storeProductId)) {
        activeFeatures.addAll(offer.unlockedFeatures);
      }
    }

    return PremiumFeature.values
        .map(
          (feature) => SubscriptionEntitlement(
            feature: feature,
            isActive: activeFeatures.contains(feature),
          ),
        )
        .toList(growable: false);
  }
}
