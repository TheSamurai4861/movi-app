import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class CanAccessPremiumFeature {
  const CanAccessPremiumFeature(this._repository);

  final SubscriptionRepository _repository;

  Future<bool> call(PremiumFeature feature) async {
    final snapshot = await _repository.getCurrentSubscription();
    return snapshot.hasAccessTo(feature);
  }
}
