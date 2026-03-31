import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class LoadAvailableSubscriptionOffers {
  const LoadAvailableSubscriptionOffers(this._repository);

  final SubscriptionRepository _repository;

  Future<List<SubscriptionOffer>> call() {
    return _repository.loadAvailableOffers();
  }
}
