import 'package:flutter/foundation.dart';

import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';

@immutable
class SubscriptionSnapshot {
  SubscriptionSnapshot({
    required this.status,
    required this.billingAvailability,
    List<SubscriptionEntitlement> entitlements =
        const <SubscriptionEntitlement>[],
    this.activePlanId,
    this.expiresAtUtc,
  }) : entitlements = List<SubscriptionEntitlement>.unmodifiable(entitlements);

  final SubscriptionStatus status;
  final BillingAvailability billingAvailability;
  final List<SubscriptionEntitlement> entitlements;
  final String? activePlanId;
  final DateTime? expiresAtUtc;

  static final SubscriptionSnapshot empty = SubscriptionSnapshot(
    status: SubscriptionStatus.inactive,
    billingAvailability: BillingAvailability.unavailable,
  );

  bool get hasActiveSubscription =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.gracePeriod;

  bool hasAccessTo(PremiumFeature feature) {
    for (final entitlement in entitlements) {
      if (entitlement.feature == feature) {
        return entitlement.isActive;
      }
    }
    return false;
  }

  SubscriptionSnapshot copyWith({
    SubscriptionStatus? status,
    BillingAvailability? billingAvailability,
    List<SubscriptionEntitlement>? entitlements,
    Object? activePlanId = _sentinel,
    Object? expiresAtUtc = _sentinel,
  }) {
    return SubscriptionSnapshot(
      status: status ?? this.status,
      billingAvailability: billingAvailability ?? this.billingAvailability,
      entitlements: entitlements ?? this.entitlements,
      activePlanId: identical(activePlanId, _sentinel)
          ? this.activePlanId
          : activePlanId as String?,
      expiresAtUtc: identical(expiresAtUtc, _sentinel)
          ? this.expiresAtUtc
          : expiresAtUtc as DateTime?,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionSnapshot &&
            other.status == status &&
            other.billingAvailability == billingAvailability &&
            listEquals(other.entitlements, entitlements) &&
            other.activePlanId == activePlanId &&
            other.expiresAtUtc == expiresAtUtc;
  }

  @override
  int get hashCode => Object.hash(
    status,
    billingAvailability,
    Object.hashAll(entitlements),
    activePlanId,
    expiresAtUtc,
  );

  @override
  String toString() {
    return 'SubscriptionSnapshot('
        'status: $status, '
        'billingAvailability: $billingAvailability, '
        'entitlements: $entitlements, '
        'activePlanId: $activePlanId, '
        'expiresAtUtc: $expiresAtUtc'
        ')';
  }
}
