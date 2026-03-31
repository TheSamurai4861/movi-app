enum SubscriptionFailureCategory { user, technical }

enum SubscriptionFailureCode {
  billingUnavailable,
  offerNotFound,
  purchaseCancelled,
  purchaseFailed,
  restoreFailed,
  storeQueryFailed,
  storeTimeout,
  providerNotConfigured,
  unknown,
}

class SubscriptionFailure implements Exception {
  const SubscriptionFailure({
    required this.category,
    required this.code,
    required this.message,
  });

  final SubscriptionFailureCategory category;
  final SubscriptionFailureCode code;
  final String message;

  bool get isUserFailure => category == SubscriptionFailureCategory.user;
  bool get isTechnicalFailure =>
      category == SubscriptionFailureCategory.technical;

  factory SubscriptionFailure.billingUnavailable() {
    return const SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.billingUnavailable,
      message:
          'Billing is unavailable on this platform or store connection failed.',
    );
  }

  factory SubscriptionFailure.offerNotFound(String offerId) {
    return SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.offerNotFound,
      message: 'Subscription offer not found: $offerId.',
    );
  }

  factory SubscriptionFailure.purchaseCancelled() {
    return const SubscriptionFailure(
      category: SubscriptionFailureCategory.user,
      code: SubscriptionFailureCode.purchaseCancelled,
      message: 'The subscription purchase was cancelled by the user.',
    );
  }

  factory SubscriptionFailure.purchaseFailed(String message) {
    return SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.purchaseFailed,
      message: message,
    );
  }

  factory SubscriptionFailure.restoreFailed(String message) {
    return SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.restoreFailed,
      message: message,
    );
  }

  factory SubscriptionFailure.storeQueryFailed(String message) {
    return SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.storeQueryFailed,
      message: message,
    );
  }

  factory SubscriptionFailure.storeTimeout(String operation) {
    return SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.storeTimeout,
      message: 'The store operation timed out: $operation.',
    );
  }

  factory SubscriptionFailure.providerNotConfigured() {
    return const SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.providerNotConfigured,
      message:
          'No subscription billing provider is configured for this platform.',
    );
  }

  factory SubscriptionFailure.unknown(String message) {
    return SubscriptionFailure(
      category: SubscriptionFailureCategory.technical,
      code: SubscriptionFailureCode.unknown,
      message: message,
    );
  }

  @override
  String toString() => message;
}
