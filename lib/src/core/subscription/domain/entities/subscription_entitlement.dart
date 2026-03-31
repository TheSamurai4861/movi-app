import 'package:flutter/foundation.dart';

import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';

@immutable
class SubscriptionEntitlement {
  const SubscriptionEntitlement({
    required this.feature,
    required this.isActive,
  });

  final PremiumFeature feature;
  final bool isActive;

  SubscriptionEntitlement copyWith({PremiumFeature? feature, bool? isActive}) {
    return SubscriptionEntitlement(
      feature: feature ?? this.feature,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionEntitlement &&
            other.feature == feature &&
            other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(feature, isActive);

  @override
  String toString() {
    return 'SubscriptionEntitlement('
        'feature: $feature, '
        'isActive: $isActive'
        ')';
  }
}
