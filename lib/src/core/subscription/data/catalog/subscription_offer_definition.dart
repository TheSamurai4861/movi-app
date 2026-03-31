import 'package:flutter/foundation.dart';

import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';

@immutable
class SubscriptionOfferDefinition {
  const SubscriptionOfferDefinition({
    required this.offerId,
    required this.storeProductId,
    required this.unlockedFeatures,
  });

  final String offerId;
  final String storeProductId;
  final List<PremiumFeature> unlockedFeatures;
}
