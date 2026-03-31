import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class PurchaseSubscription {
  const PurchaseSubscription(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionSnapshot> call({required String offerId}) {
    return _repository.purchaseSubscription(offerId: offerId);
  }
}
