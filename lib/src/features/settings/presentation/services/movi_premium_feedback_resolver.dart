import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';

enum MoviPremiumFeedbackKind {
  purchaseSucceeded,
  restoreSucceeded,
  noPurchaseFound,
  billingUnavailable,
  networkUnavailable,
  accountRequired,
  purchaseCancelled,
  technicalFailure,
}

class MoviPremiumFeedbackResolver {
  const MoviPremiumFeedbackResolver();

  MoviPremiumFeedbackKind resolveRestoreSuccess({
    required bool hasActiveSubscription,
  }) {
    return hasActiveSubscription
        ? MoviPremiumFeedbackKind.restoreSucceeded
        : MoviPremiumFeedbackKind.noPurchaseFound;
  }

  MoviPremiumFeedbackKind resolveFailure(SubscriptionFailure failure) {
    switch (failure.code) {
      case SubscriptionFailureCode.billingUnavailable:
      case SubscriptionFailureCode.providerNotConfigured:
        return MoviPremiumFeedbackKind.billingUnavailable;
      case SubscriptionFailureCode.purchaseCancelled:
        return MoviPremiumFeedbackKind.purchaseCancelled;
      case SubscriptionFailureCode.storeTimeout:
        return MoviPremiumFeedbackKind.networkUnavailable;
      case SubscriptionFailureCode.offerNotFound:
      case SubscriptionFailureCode.purchaseFailed:
      case SubscriptionFailureCode.restoreFailed:
      case SubscriptionFailureCode.storeQueryFailed:
      case SubscriptionFailureCode.unknown:
        if (_looksLikeNetworkFailure(failure)) {
          return MoviPremiumFeedbackKind.networkUnavailable;
        }
        return MoviPremiumFeedbackKind.technicalFailure;
    }
  }

  bool _looksLikeNetworkFailure(SubscriptionFailure failure) {
    final message = failure.message.toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('offline') ||
        message.contains('socket') ||
        message.contains('timed out') ||
        message.contains('timeout');
  }
}
