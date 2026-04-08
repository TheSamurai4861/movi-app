import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
        canAccessPremiumFeatureProvider.overrideWith(
          (ref, feature) async => false,
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

