import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/movi_premium_providers.dart';

void main() {
  group('moviPremiumPageStateProvider', () {
    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _awaitAuthSnapshot(ProviderContainer container) async {
      final completer = Completer<void>();
      final sub = container.listen<AsyncValue<AuthSnapshot>>(
        moviPremiumAuthProvider,
        (prev, next) {
          if (next.hasValue && !completer.isCompleted) {
            completer.complete();
          }
        },
        fireImmediately: true,
      );
      try {
        await completer.future.timeout(const Duration(seconds: 2));
      } finally {
        sub.close();
      }
    }

    test('disables purchase and restore when account is missing', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          moviPremiumAuthProvider.overrideWith(
            (ref) => Stream<AuthSnapshot>.value(AuthSnapshot.unauthenticated),
          ),
          currentSubscriptionProvider.overrideWith(
            (ref) async => SubscriptionSnapshot(
              status: SubscriptionStatus.inactive,
              billingAvailability: BillingAvailability.available,
            ),
          ),
          subscriptionOffersProvider.overrideWith(
            (ref) async => const <SubscriptionOffer>[
              SubscriptionOffer(
                id: 'monthly',
                storeProductId: 'monthly',
                title: 'Monthly',
                description: 'Monthly premium access',
                displayPrice: '€4.99',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await _awaitAuthSnapshot(container);
      await container.read(currentSubscriptionProvider.future);
      await container.read(subscriptionOffersProvider.future);
      final state = container.read(moviPremiumPageStateProvider);

      expect(state.shouldShowAccountHint, isTrue);
      expect(state.canPurchase, isFalse);
      expect(state.canRestore, isFalse);
      expect(state.offers, isNotEmpty);
    });

    test('enables purchase and restore for authenticated users', () async {
      const session = AuthSession(userId: 'user-1');

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(session: session),
          ),
          moviPremiumAuthProvider.overrideWith(
            (ref) => Stream<AuthSnapshot>.value(
              const AuthSnapshot(
                status: AuthStatus.authenticated,
                session: session,
              ),
            ),
          ),
          currentSubscriptionProvider.overrideWith(
            (ref) async => SubscriptionSnapshot(
              status: SubscriptionStatus.inactive,
              billingAvailability: BillingAvailability.available,
            ),
          ),
          subscriptionOffersProvider.overrideWith(
            (ref) async => const <SubscriptionOffer>[
              SubscriptionOffer(
                id: 'annual',
                storeProductId: 'annual',
                title: 'Annual',
                description: 'Annual premium access',
                displayPrice: '€39.99',
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      await _awaitAuthSnapshot(container);
      final snapshot = await container.read(currentSubscriptionProvider.future);
      await container.read(subscriptionOffersProvider.future);
      final state = container.read(moviPremiumPageStateProvider);

      expect(snapshot.status, SubscriptionStatus.inactive);
      expect(state.shouldShowAccountHint, isFalse);
      expect(state.canPurchase, isTrue);
      expect(state.canRestore, isTrue);
      expect(state.hasActiveSubscription, isFalse);
    });

    test('surfaces the active plan when subscription is already enabled', () async {
      const session = AuthSession(userId: 'user-2');

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(session: session),
          ),
          moviPremiumAuthProvider.overrideWith(
            (ref) => Stream<AuthSnapshot>.value(
              const AuthSnapshot(
                status: AuthStatus.authenticated,
                session: session,
              ),
            ),
          ),
          currentSubscriptionProvider.overrideWith(
            (ref) async => SubscriptionSnapshot(
              status: SubscriptionStatus.active,
              billingAvailability: BillingAvailability.available,
              activePlanId: 'movi_premium_annual',
            ),
          ),
          subscriptionOffersProvider.overrideWith(
            (ref) async => const <SubscriptionOffer>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await _awaitAuthSnapshot(container);
      await container.read(currentSubscriptionProvider.future);
      final state = container.read(moviPremiumPageStateProvider);

      expect(state.hasActiveSubscription, isTrue);
      expect(state.activePlanId, 'movi_premium_annual');
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session});

  final AuthSession? session;

  @override
  AuthSession? get currentSession => session;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => Stream<AuthSnapshot>.value(
    session == null
        ? AuthSnapshot.unauthenticated
        : AuthSnapshot(status: AuthStatus.authenticated, session: session),
  );

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> verifyOtp({required String email, required String token}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}
