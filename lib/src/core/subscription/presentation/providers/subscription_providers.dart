import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/application/usecases/get_current_subscription.dart';
import 'package:movi/src/core/subscription/application/usecases/load_available_subscription_offers.dart';
import 'package:movi/src/core/subscription/application/usecases/purchase_subscription.dart';
import 'package:movi/src/core/subscription/application/usecases/refresh_subscription.dart';
import 'package:movi/src/core/subscription/application/usecases/restore_subscription.dart';
import 'package:movi/src/core/subscription/application/services/server_subscription_entitlement_service.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';
import 'package:movi/src/core/subscription/subscription_module.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';

const bool _forcePremiumForTesting = bool.fromEnvironment(
  'FORCE_PREMIUM',
  defaultValue: false,
);

const bool _allowForcePremiumInRelease = bool.fromEnvironment(
  'ALLOW_FORCE_PREMIUM_IN_RELEASE',
  defaultValue: false,
);

void _ensureSubscriptionModule(GetIt locator) {
  if (!locator.isRegistered<SubscriptionRepository>()) {
    SubscriptionModule.register(locator);
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final locator = ref.watch(slProvider);
  _ensureSubscriptionModule(locator);
  return locator<SubscriptionRepository>();
});

final getCurrentSubscriptionUseCaseProvider = Provider<GetCurrentSubscription>((
  ref,
) {
  final locator = ref.watch(slProvider);
  _ensureSubscriptionModule(locator);
  return locator<GetCurrentSubscription>();
});

final loadAvailableSubscriptionOffersUseCaseProvider =
    Provider<LoadAvailableSubscriptionOffers>((ref) {
      final locator = ref.watch(slProvider);
      _ensureSubscriptionModule(locator);
      return locator<LoadAvailableSubscriptionOffers>();
    });

final purchaseSubscriptionUseCaseProvider = Provider<PurchaseSubscription>((
  ref,
) {
  final locator = ref.watch(slProvider);
  _ensureSubscriptionModule(locator);
  return locator<PurchaseSubscription>();
});

final restoreSubscriptionUseCaseProvider = Provider<RestoreSubscription>((ref) {
  final locator = ref.watch(slProvider);
  _ensureSubscriptionModule(locator);
  return locator<RestoreSubscription>();
});

final refreshSubscriptionUseCaseProvider = Provider<RefreshSubscription>((ref) {
  final locator = ref.watch(slProvider);
  _ensureSubscriptionModule(locator);
  return locator<RefreshSubscription>();
});

final canAccessPremiumFeatureUseCaseProvider =
    Provider<CanAccessPremiumFeature>((ref) {
      final locator = ref.watch(slProvider);
      _ensureSubscriptionModule(locator);
      return locator<CanAccessPremiumFeature>();
    });

final currentSubscriptionProvider = FutureProvider<SubscriptionSnapshot>((ref) {
  final getCurrentSubscription = ref.watch(
    getCurrentSubscriptionUseCaseProvider,
  );

  // Base snapshot (store/local-first).
  return getCurrentSubscription().then((localSnapshot) async {
    // Test override: allow forcing Premium for beta builds.
    // Release builds require an explicit opt-in.
    if (_forcePremiumForTesting &&
        (!kReleaseMode || _allowForcePremiumInRelease)) {
      return SubscriptionSnapshot(
        status: SubscriptionStatus.active,
        billingAvailability: localSnapshot.billingAvailability,
        entitlements: PremiumFeature.values
            .map(
              (feature) =>
                  SubscriptionEntitlement(feature: feature, isActive: true),
            )
            .toList(growable: false),
        activePlanId: 'forced_premium_testing',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(days: 365)),
      );
    }

    final client = ref.read(supabaseClientProvider);
    if (client == null) return localSnapshot;
    if (client.auth.currentUser == null) return localSnapshot;

    try {
      final service = ServerSubscriptionEntitlementService(client);
      final decision = await service.readCurrent();
      if (!decision.hasServerData) return localSnapshot;

      // Prefer server status when connected, keep local billing availability.
      return decision.snapshot.copyWith(
        billingAvailability: localSnapshot.billingAvailability,
      );
    } catch (_) {
      // Supabase unavailable or RLS blocked; keep app functional.
      return localSnapshot;
    }
  });
});

final subscriptionOffersProvider = FutureProvider<List<SubscriptionOffer>>((
  ref,
) {
  final loadOffers = ref.watch(loadAvailableSubscriptionOffersUseCaseProvider);
  return loadOffers();
});

final canAccessPremiumFeatureProvider =
    FutureProvider.family<bool, PremiumFeature>((ref, feature) {
      if (_forcePremiumForTesting &&
          (!kReleaseMode || _allowForcePremiumInRelease)) {
        return Future<bool>.value(true);
      }
      final canAccessPremiumFeature = ref.watch(
        canAccessPremiumFeatureUseCaseProvider,
      );
      return canAccessPremiumFeature(feature);
    });

enum SubscriptionActionPhase { idle, loading, success, failure }

@immutable
class SubscriptionActionState {
  const SubscriptionActionState({
    required this.phase,
    this.message,
    this.failureCategory,
    this.failureCode,
  });

  final SubscriptionActionPhase phase;
  final String? message;
  final SubscriptionFailureCategory? failureCategory;
  final SubscriptionFailureCode? failureCode;

  static const SubscriptionActionState idle = SubscriptionActionState(
    phase: SubscriptionActionPhase.idle,
  );

  SubscriptionActionState copyWith({
    SubscriptionActionPhase? phase,
    Object? message = _sentinel,
    Object? failureCategory = _sentinel,
    Object? failureCode = _sentinel,
  }) {
    return SubscriptionActionState(
      phase: phase ?? this.phase,
      message: identical(message, _sentinel)
          ? this.message
          : message as String?,
      failureCategory: identical(failureCategory, _sentinel)
          ? this.failureCategory
          : failureCategory as SubscriptionFailureCategory?,
      failureCode: identical(failureCode, _sentinel)
          ? this.failureCode
          : failureCode as SubscriptionFailureCode?,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubscriptionActionState &&
            other.phase == phase &&
            other.message == message &&
            other.failureCategory == failureCategory &&
            other.failureCode == failureCode;
  }

  @override
  int get hashCode => Object.hash(phase, message, failureCategory, failureCode);
}

class SubscriptionActionController extends Notifier<SubscriptionActionState> {
  @override
  SubscriptionActionState build() {
    return SubscriptionActionState.idle;
  }

  Future<void> purchase(String offerId) async {
    state = const SubscriptionActionState(
      phase: SubscriptionActionPhase.loading,
    );

    try {
      final purchaseSubscription = ref.read(
        purchaseSubscriptionUseCaseProvider,
      );
      await purchaseSubscription(offerId: offerId);
      state = const SubscriptionActionState(
        phase: SubscriptionActionPhase.success,
      );
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionOffersProvider);
    } on SubscriptionFailure catch (failure) {
      state = SubscriptionActionState(
        phase: SubscriptionActionPhase.failure,
        message: failure.message,
        failureCategory: failure.category,
        failureCode: failure.code,
      );
    } catch (error) {
      state = SubscriptionActionState(
        phase: SubscriptionActionPhase.failure,
        message: error.toString(),
        failureCategory: SubscriptionFailureCategory.technical,
        failureCode: SubscriptionFailureCode.unknown,
      );
    }
  }

  Future<void> restore() async {
    state = const SubscriptionActionState(
      phase: SubscriptionActionPhase.loading,
    );

    try {
      final restoreSubscription = ref.read(restoreSubscriptionUseCaseProvider);
      await restoreSubscription();
      state = const SubscriptionActionState(
        phase: SubscriptionActionPhase.success,
      );
      ref.invalidate(currentSubscriptionProvider);
    } on SubscriptionFailure catch (failure) {
      state = SubscriptionActionState(
        phase: SubscriptionActionPhase.failure,
        message: failure.message,
        failureCategory: failure.category,
        failureCode: failure.code,
      );
    } catch (error) {
      state = SubscriptionActionState(
        phase: SubscriptionActionPhase.failure,
        message: error.toString(),
        failureCategory: SubscriptionFailureCategory.technical,
        failureCode: SubscriptionFailureCode.unknown,
      );
    }
  }

  Future<void> refresh() async {
    state = const SubscriptionActionState(
      phase: SubscriptionActionPhase.loading,
    );

    try {
      final refreshSubscription = ref.read(refreshSubscriptionUseCaseProvider);
      await refreshSubscription();
      state = const SubscriptionActionState(
        phase: SubscriptionActionPhase.success,
      );
      ref.invalidate(currentSubscriptionProvider);
    } on SubscriptionFailure catch (failure) {
      state = SubscriptionActionState(
        phase: SubscriptionActionPhase.failure,
        message: failure.message,
        failureCategory: failure.category,
        failureCode: failure.code,
      );
    } catch (error) {
      state = SubscriptionActionState(
        phase: SubscriptionActionPhase.failure,
        message: error.toString(),
        failureCategory: SubscriptionFailureCategory.technical,
        failureCode: SubscriptionFailureCode.unknown,
      );
    }
  }

  void clearFeedback() {
    state = SubscriptionActionState.idle;
  }
}

final subscriptionActionControllerProvider =
    NotifierProvider<SubscriptionActionController, SubscriptionActionState>(
      SubscriptionActionController.new,
    );
