import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/notifications/local_notification_gateway.dart';
import 'package:movi/src/core/notifications/local_notification_gateway_provider.dart';
import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/features/series_tracking/presentation/providers/series_tracking_providers.dart';
import 'package:movi/src/features/series_tracking/presentation/widgets/series_tracking_bootstrapper.dart';

void main() {
  testWidgets(
    'SeriesTrackingBootstrapper degrades gracefully when notification init fails',
    (tester) async {
      final notificationGateway = _ThrowingLocalNotificationGateway();
      final toggleNotifier = _FakeSeriesTrackingToggleNotifier();
      final container = ProviderContainer(
        overrides: [
          localNotificationGatewayProvider.overrideWithValue(notificationGateway),
          seriesTrackingToggleProvider.overrideWith(() => toggleNotifier),
          canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
            CanAccessPremiumFeature(
              _FakeSubscriptionRepository(
                snapshot: SubscriptionSnapshot(
                  status: SubscriptionStatus.active,
                  billingAvailability: BillingAvailability.available,
                  entitlements: const [
                    SubscriptionEntitlement(
                      feature: PremiumFeature.seriesEpisodeTracking,
                      isActive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: SeriesTrackingBootstrapper(
              child: SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();

      expect(notificationGateway.initializeCalls, 1);
      expect(toggleNotifier.refreshCalls, 1);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _ThrowingLocalNotificationGateway implements LocalNotificationGateway {
  int initializeCalls = 0;

  @override
  Stream<SeriesNotificationNavigationIntent> get navigationIntents =>
      const Stream<SeriesNotificationNavigationIntent>.empty();

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    throw StateError('notifications_init_failed');
  }

  @override
  Future<bool> requestSeriesNotificationsPermissionIfNeeded() async => false;

  @override
  Future<bool> areSeriesNotificationsEnabled() async => false;

  @override
  Future<void> showNewEpisodeNotification(
    NewEpisodeNotificationRequest request,
  ) async {}
}

final class _FakeSeriesTrackingToggleNotifier extends SeriesTrackingToggleNotifier {
  int refreshCalls = 0;

  @override
  void build() {}

  @override
  Future<void> refreshAllTrackedSeriesStatuses() async {
    refreshCalls += 1;
  }
}

final class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required this.snapshot});

  final SubscriptionSnapshot snapshot;

  @override
  Future<SubscriptionSnapshot> getCurrentSubscription() async => snapshot;

  @override
  Future<List<SubscriptionOffer>> loadAvailableOffers() async => const [];

  @override
  Future<SubscriptionSnapshot> purchaseSubscription({required String offerId}) {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> refreshSubscription() {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> restoreSubscription() {
    throw UnimplementedError();
  }
}
