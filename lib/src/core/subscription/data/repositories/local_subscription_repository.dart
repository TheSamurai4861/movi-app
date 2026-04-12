import 'package:movi/src/core/subscription/data/datasources/subscription_local_cache_data_source.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';

class LocalSubscriptionRepository implements SubscriptionRepository {
  LocalSubscriptionRepository(this._cache);

  final SubscriptionLocalCacheDataSource _cache;

  @override
  Future<SubscriptionSnapshot> getCurrentSubscription() {
    return _cache.read();
  }

  @override
  Future<SubscriptionSnapshot> purchaseSubscription({
    required String offerId,
  }) async {
    throw UnsupportedError(
      'Subscription purchase provider is not configured yet. '
      'Register a concrete store/provider-backed SubscriptionRepository '
      'before calling purchaseSubscription().',
    );
  }

  @override
  Future<SubscriptionSnapshot> restoreSubscription() async {
    throw UnsupportedError(
      'Subscription restore provider is not configured yet. '
      'Register a concrete store/provider-backed SubscriptionRepository '
      'before calling restoreSubscription().',
    );
  }

  @override
  Future<List<SubscriptionOffer>> loadAvailableOffers() async {
    return const <SubscriptionOffer>[];
  }

  @override
  Future<SubscriptionSnapshot> refreshSubscription() {
    return _cache.read();
  }
}
