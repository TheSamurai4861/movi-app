import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/features/settings/presentation/services/movi_premium_feedback_resolver.dart';

final moviPremiumFeedbackResolverProvider =
    Provider<MoviPremiumFeedbackResolver>((ref) {
      return const MoviPremiumFeedbackResolver();
    });

final moviPremiumAuthProvider = StreamProvider<AuthSnapshot>((ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  final currentSession = repository.currentSession;

  if (currentSession == null) {
    yield AuthSnapshot.unauthenticated;
  } else {
    yield AuthSnapshot(
      status: AuthStatus.authenticated,
      session: currentSession,
    );
  }

  yield* repository.onAuthStateChange;
});

@immutable
class MoviPremiumPageState {
  const MoviPremiumPageState({
    required this.isAuthenticated,
    required this.isLoadingSubscription,
    required this.isLoadingOffers,
    required this.billingAvailability,
    required this.hasActiveSubscription,
    required this.activePlanId,
    required this.offers,
  });

  final bool isAuthenticated;
  final bool isLoadingSubscription;
  final bool isLoadingOffers;
  final BillingAvailability billingAvailability;
  final bool hasActiveSubscription;
  final String? activePlanId;
  final List<SubscriptionOffer> offers;

  bool get isBillingUnavailable =>
      billingAvailability == BillingAvailability.unavailable;

  bool get isRestoreOnly =>
      billingAvailability == BillingAvailability.restoreOnly;

  bool get canPurchase =>
      isAuthenticated && billingAvailability == BillingAvailability.available;

  bool get canRestore =>
      isAuthenticated && billingAvailability != BillingAvailability.unavailable;

  bool get shouldShowAccountHint => !isAuthenticated;

  bool get isInitialLoading =>
      isLoadingSubscription && activePlanId == null && offers.isEmpty;
}

final moviPremiumPageStateProvider = Provider<MoviPremiumPageState>((ref) {
  final authSnapshot = ref
      .watch(moviPremiumAuthProvider)
      .maybeWhen(data: (value) => value, orElse: () => AuthSnapshot.unknown);
  final subscriptionAsync = ref.watch(currentSubscriptionProvider);
  final offersAsync = ref.watch(subscriptionOffersProvider);

  final snapshot = subscriptionAsync.asData?.value;
  final offers = offersAsync.asData?.value ?? const <SubscriptionOffer>[];

  return MoviPremiumPageState(
    isAuthenticated: authSnapshot.isAuthenticated,
    isLoadingSubscription: snapshot == null && subscriptionAsync.isLoading,
    isLoadingOffers: offers.isEmpty && offersAsync.isLoading,
    billingAvailability:
        snapshot?.billingAvailability ?? BillingAvailability.unavailable,
    hasActiveSubscription: snapshot?.hasActiveSubscription ?? false,
    activePlanId: snapshot?.activePlanId,
    offers: offers,
  );
});

enum MoviPremiumOperation { purchase, restore, refresh }

enum MoviPremiumActionPhase { idle, loading, success, failure }

@immutable
class MoviPremiumPageActionState {
  const MoviPremiumPageActionState({
    required this.phase,
    this.operation,
    this.feedbackKind,
  });

  final MoviPremiumActionPhase phase;
  final MoviPremiumOperation? operation;
  final MoviPremiumFeedbackKind? feedbackKind;

  static const MoviPremiumPageActionState idle = MoviPremiumPageActionState(
    phase: MoviPremiumActionPhase.idle,
  );

  bool get isBusy => phase == MoviPremiumActionPhase.loading;
}

class MoviPremiumPageController extends Notifier<MoviPremiumPageActionState> {
  AppLogger? _logger;

  @override
  MoviPremiumPageActionState build() {
    final locator = ref.watch(slProvider);
    if (locator.isRegistered<AppLogger>()) {
      _logger = locator<AppLogger>();
    }
    return MoviPremiumPageActionState.idle;
  }

  Future<void> purchase(String offerId) async {
    final authSnapshot = ref
        .read(moviPremiumAuthProvider)
        .maybeWhen(data: (value) => value, orElse: () => AuthSnapshot.unknown);

    if (!authSnapshot.isAuthenticated) {
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.purchase,
        feedbackKind: MoviPremiumFeedbackKind.accountRequired,
      );
      return;
    }

    state = const MoviPremiumPageActionState(
      phase: MoviPremiumActionPhase.loading,
      operation: MoviPremiumOperation.purchase,
    );

    try {
      final purchaseSubscription = ref.read(
        purchaseSubscriptionUseCaseProvider,
      );
      await purchaseSubscription(offerId: offerId);
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionOffersProvider);
      _logger?.info(
        'Premium purchase completed for offer=$offerId.',
        category: 'subscription',
      );
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.success,
        operation: MoviPremiumOperation.purchase,
        feedbackKind: MoviPremiumFeedbackKind.purchaseSucceeded,
      );
    } on SubscriptionFailure catch (failure) {
      final feedbackKind = ref
          .read(moviPremiumFeedbackResolverProvider)
          .resolveFailure(failure);
      _logger?.warn(
        'Premium purchase failed: ${failure.message}',
        category: 'subscription',
      );
      state = MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.purchase,
        feedbackKind: feedbackKind,
      );
    } catch (error, stackTrace) {
      _logger?.error('Unexpected premium purchase failure.', error, stackTrace);
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.purchase,
        feedbackKind: MoviPremiumFeedbackKind.technicalFailure,
      );
    }
  }

  Future<void> restore() async {
    final authSnapshot = ref
        .read(moviPremiumAuthProvider)
        .maybeWhen(data: (value) => value, orElse: () => AuthSnapshot.unknown);

    if (!authSnapshot.isAuthenticated) {
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.restore,
        feedbackKind: MoviPremiumFeedbackKind.accountRequired,
      );
      return;
    }

    state = const MoviPremiumPageActionState(
      phase: MoviPremiumActionPhase.loading,
      operation: MoviPremiumOperation.restore,
    );

    try {
      final restoreSubscription = ref.read(restoreSubscriptionUseCaseProvider);
      final snapshot = await restoreSubscription();
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionOffersProvider);
      final feedbackKind = ref
          .read(moviPremiumFeedbackResolverProvider)
          .resolveRestoreSuccess(
            hasActiveSubscription: snapshot.hasActiveSubscription,
          );
      _logger?.info(
        'Premium restore completed. active=${snapshot.hasActiveSubscription}.',
        category: 'subscription',
      );
      state = MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.success,
        operation: MoviPremiumOperation.restore,
        feedbackKind: feedbackKind,
      );
    } on SubscriptionFailure catch (failure) {
      final feedbackKind = ref
          .read(moviPremiumFeedbackResolverProvider)
          .resolveFailure(failure);
      _logger?.warn(
        'Premium restore failed: ${failure.message}',
        category: 'subscription',
      );
      state = MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.restore,
        feedbackKind: feedbackKind,
      );
    } catch (error, stackTrace) {
      _logger?.error('Unexpected premium restore failure.', error, stackTrace);
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.restore,
        feedbackKind: MoviPremiumFeedbackKind.technicalFailure,
      );
    }
  }

  Future<void> refresh() async {
    state = const MoviPremiumPageActionState(
      phase: MoviPremiumActionPhase.loading,
      operation: MoviPremiumOperation.refresh,
    );

    try {
      final refreshSubscription = ref.read(refreshSubscriptionUseCaseProvider);
      await refreshSubscription();
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(subscriptionOffersProvider);
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.success,
        operation: MoviPremiumOperation.refresh,
      );
    } on SubscriptionFailure catch (failure) {
      final feedbackKind = ref
          .read(moviPremiumFeedbackResolverProvider)
          .resolveFailure(failure);
      _logger?.warn(
        'Premium refresh failed: ${failure.message}',
        category: 'subscription',
      );
      state = MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.refresh,
        feedbackKind: feedbackKind,
      );
    } catch (error, stackTrace) {
      _logger?.error('Unexpected premium refresh failure.', error, stackTrace);
      state = const MoviPremiumPageActionState(
        phase: MoviPremiumActionPhase.failure,
        operation: MoviPremiumOperation.refresh,
        feedbackKind: MoviPremiumFeedbackKind.technicalFailure,
      );
    }
  }

  void clearFeedback() {
    state = MoviPremiumPageActionState.idle;
  }
}

final moviPremiumPageControllerProvider =
    NotifierProvider<MoviPremiumPageController, MoviPremiumPageActionState>(
      MoviPremiumPageController.new,
    );
