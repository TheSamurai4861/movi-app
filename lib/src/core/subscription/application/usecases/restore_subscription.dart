import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class RestoreSubscription {
  const RestoreSubscription(this._repository);

  final SubscriptionRepository _repository;

  Future<SubscriptionSnapshot> call() {
    return _repository.restoreSubscription();
  }
}
