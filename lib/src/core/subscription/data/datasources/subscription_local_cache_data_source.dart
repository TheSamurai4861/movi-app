import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';

class SubscriptionLocalCacheDataSource {
  SubscriptionSnapshot _cachedSnapshot = SubscriptionSnapshot.empty;

  Future<SubscriptionSnapshot> read() async {
    return _cachedSnapshot;
  }

  Future<void> write(SubscriptionSnapshot snapshot) async {
    _cachedSnapshot = snapshot;
  }

  Future<void> clear() async {
    _cachedSnapshot = SubscriptionSnapshot.empty;
  }
}
