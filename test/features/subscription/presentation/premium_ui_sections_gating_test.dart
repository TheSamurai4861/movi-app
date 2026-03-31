import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_saga_section.dart';
import 'package:movi/src/features/search/presentation/widgets/watch_providers_grid.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/search/domain/entities/watch_provider.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';

void main() {
  testWidgets('Non-premium hides saga section and providers grid', (tester) async {
    final container = ProviderContainer(
      overrides: [
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.inactive,
                billingAvailability: BillingAvailability.available,
                entitlements: [
                  SubscriptionEntitlement(
                    feature: PremiumFeature.extendedDiscoveryDetails,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        watchProvidersProvider.overrideWith(
          (ref) async => const [
            WatchProvider(providerId: 1, providerName: 'TestProvider'),
          ],
        ),
        sagaMoviesProvider.overrideWith(
          (ref, saga) async => const [
            MoviMedia(id: 'm1', title: 'Movie 1', type: MoviMediaType.movie),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                const _ProvidersGridSection(),
                MovieDetailSagaSection(
                  sagaLink: SagaSummary(
                    id: SagaId('s1'),
                    title: MediaTitle('Saga'),
                  ),
                  currentMovieId: 'm1',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WatchProvidersGrid), findsNothing);
    expect(find.text('Voir la page'), findsNothing);
  });

  testWidgets('Premium shows saga section and providers grid', (tester) async {
    final container = ProviderContainer(
      overrides: [
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.active,
                billingAvailability: BillingAvailability.available,
                entitlements: [
                  SubscriptionEntitlement(
                    feature: PremiumFeature.extendedDiscoveryDetails,
                    isActive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        watchProvidersProvider.overrideWith(
          (ref) async => const [
            WatchProvider(providerId: 1, providerName: 'TestProvider'),
          ],
        ),
        sagaMoviesProvider.overrideWith(
          (ref, saga) async => const [
            MoviMedia(id: 'm1', title: 'Movie 1', type: MoviMediaType.movie),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                const _ProvidersGridSection(),
                MovieDetailSagaSection(
                  sagaLink: SagaSummary(
                    id: SagaId('s1'),
                    title: MediaTitle('Saga'),
                  ),
                  currentMovieId: 'm1',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WatchProvidersGrid), findsOneWidget);
    expect(find.text('Voir la page'), findsOneWidget);
  });
}

class _ProvidersGridSection extends ConsumerWidget {
  const _ProvidersGridSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPremium = ref
        .watch(
          canAccessPremiumFeatureProvider(PremiumFeature.extendedDiscoveryDetails),
        )
        .maybeWhen(data: (value) => value, orElse: () => false);

    if (!hasPremium) return const SizedBox.shrink();
    return const WatchProvidersGrid(
      horizontalPadding: 0,
      maxContentWidth: double.infinity,
    );
  }
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
  Future<SubscriptionSnapshot> refreshSubscription() {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> restoreSubscription() {
    throw UnimplementedError();
  }
}

