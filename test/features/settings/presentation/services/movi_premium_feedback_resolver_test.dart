import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/subscription/domain/failures/subscription_failure.dart';
import 'package:movi/src/features/settings/presentation/services/movi_premium_feedback_resolver.dart';

void main() {
  group('MoviPremiumFeedbackResolver', () {
    const resolver = MoviPremiumFeedbackResolver();

    test('maps billing unavailable errors explicitly', () {
      final feedback = resolver.resolveFailure(
        SubscriptionFailure.billingUnavailable(),
      );

      expect(feedback, MoviPremiumFeedbackKind.billingUnavailable);
    });

    test('maps cancelled purchases to a user-facing cancelled state', () {
      final feedback = resolver.resolveFailure(
        SubscriptionFailure.purchaseCancelled(),
      );

      expect(feedback, MoviPremiumFeedbackKind.purchaseCancelled);
    });

    test('maps timeout-like failures to network unavailable', () {
      final feedback = resolver.resolveFailure(
        SubscriptionFailure.storeTimeout('restore'),
      );

      expect(feedback, MoviPremiumFeedbackKind.networkUnavailable);
    });

    test('maps restore success without active plan to no purchase found', () {
      final feedback = resolver.resolveRestoreSuccess(
        hasActiveSubscription: false,
      );

      expect(feedback, MoviPremiumFeedbackKind.noPurchaseFound);
    });

    test('maps generic technical failures to technical failure', () {
      final feedback = resolver.resolveFailure(
        SubscriptionFailure.purchaseFailed('Unexpected store state.'),
      );

      expect(feedback, MoviPremiumFeedbackKind.technicalFailure);
    });
  });
}
