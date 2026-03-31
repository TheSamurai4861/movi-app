import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class GetCurrentSubscription {
  const GetCurrentSubscription(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionSnapshot> call() {
    return _repository.getCurrentSubscription();
  }
}
