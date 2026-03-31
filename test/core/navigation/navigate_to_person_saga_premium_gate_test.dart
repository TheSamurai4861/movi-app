import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

void main() {
  testWidgets('navigateToPersonDetail shows premium sheet and does not navigate', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.inactive,
                billingAvailability: BillingAvailability.available,
                entitlements: const [
                  SubscriptionEntitlement(
                    feature: PremiumFeature.extendedDiscoveryDetails,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Consumer(
              builder: (context, ref, _) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => navigateToPersonDetail(
                        context,
                        ref,
                        person: PersonSummary(
                          id: const PersonId('1'),
                          name: 'Test',
                        ),
                      ),
                      child: const Text('go'),
                    ),
                  ),
                );
              },
            );
          },
        ),
        GoRoute(
          path: '/person',
          builder: (context, state) => const Scaffold(body: Text('person')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final localizer = MoviPremiumLocalizer.fromBuildContext(
      tester.element(find.byType(Scaffold)),
    );
    expect(find.text(localizer.contextualUpsellTitle), findsOneWidget);
    expect(find.text('person'), findsNothing);
  });
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
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
  Future<SubscriptionSnapshot> restoreSubscription() {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> refreshSubscription() {
    throw UnimplementedError();
  }
}

