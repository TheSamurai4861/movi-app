import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionSnapshot> getCurrentSubscription();

  Future<List<SubscriptionOffer>> loadAvailableOffers();

  Future<SubscriptionSnapshot> purchaseSubscription({required String offerId});

  Future<SubscriptionSnapshot> restoreSubscription();

  Future<SubscriptionSnapshot> refreshSubscription();
}
