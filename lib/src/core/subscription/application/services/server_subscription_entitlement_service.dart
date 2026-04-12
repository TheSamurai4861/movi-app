import 'package:flutter/foundation.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@immutable
class ServerEntitlementDecision {
  const ServerEntitlementDecision({
    required this.hasServerData,
    required this.snapshot,
  });

  final bool hasServerData;
  final SubscriptionSnapshot snapshot;
}

class ServerSubscriptionEntitlementService {
  const ServerSubscriptionEntitlementService(this._client);

  final SupabaseClient _client;

  Future<ServerEntitlementDecision> readCurrent() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return ServerEntitlementDecision(
        hasServerData: false,
        snapshot: SubscriptionSnapshot.empty,
      );
    }

    final rows = await _client
        .from('subscription_entitlements')
        .select('status, entitlements, active_plan_id, expires_at')
        .eq('user_id', user.id)
        .order('last_verified_at', ascending: false)
        .limit(1);

    final list = rows as List<dynamic>;
    if (list.isEmpty) {
      return ServerEntitlementDecision(
        hasServerData: false,
        snapshot: SubscriptionSnapshot.empty,
      );
    }

    final row = list.first as Map;
    final statusRaw = (row['status'] ?? '').toString();

    final serverStatus = switch (statusRaw) {
      'active' => SubscriptionStatus.active,
      'grace' => SubscriptionStatus.gracePeriod,
      'expired' => SubscriptionStatus.expired,
      'revoked' => SubscriptionStatus.inactive,
      _ => SubscriptionStatus.inactive,
    };

    final expiresAt = row['expires_at'];
    final expiresAtUtc = expiresAt == null
        ? null
        : DateTime.tryParse(expiresAt.toString())?.toUtc();

    final activePlanId = row['active_plan_id']?.toString();

    final entitlementsJson = row['entitlements'];
    final enabled = _parseEnabledFeatures(entitlementsJson);

    final entitlements = PremiumFeature.values
        .map(
          (feature) => SubscriptionEntitlement(
            feature: feature,
            isActive: enabled.contains(feature),
          ),
        )
        .toList(growable: false);

    return ServerEntitlementDecision(
      hasServerData: true,
      snapshot: SubscriptionSnapshot(
        status: serverStatus,
        // Billing availability is store-local; caller will overwrite it.
        billingAvailability: SubscriptionSnapshot.empty.billingAvailability,
        entitlements: entitlements,
        activePlanId: activePlanId,
        expiresAtUtc: expiresAtUtc,
      ),
    );
  }

  Set<PremiumFeature> _parseEnabledFeatures(Object? json) {
    // We accept either:
    // - { "features": ["cloudLibrarySync", ...] }
    // - { "all": true }
    // Default: none.
    if (json is Map) {
      final all = json['all'];
      if (all == true) return PremiumFeature.values.toSet();

      final features = json['features'];
      if (features is List) {
        final set = <PremiumFeature>{};
        for (final raw in features) {
          final name = raw?.toString();
          if (name == null) continue;
          for (final feature in PremiumFeature.values) {
            if (feature.name == name) set.add(feature);
          }
        }
        return set;
      }
    }
    return const <PremiumFeature>{};
  }
}
