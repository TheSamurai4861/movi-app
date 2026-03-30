import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_media_card.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
import 'package:movi/src/features/home/presentation/widgets/home_iptv_section.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  test('displayCategoryTitle strips the provider prefix when present', () {
    expect(displayCategoryTitle('Salon/Action'), 'Action');
    expect(displayCategoryTitle('Action'), 'Action');
  });

  testWidgets('HomeIptvSection renders degraded IPTV cards without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HomeIptvSection(
              categoryTitle: 'Salon/Action',
              items: <ContentReference>[
                ContentReference(
                  id: 'xtream:100',
                  title: MediaTitle('The Matrix'),
                  type: ContentType.movie,
                  poster: null,
                  year: null,
                  rating: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Voir tout'), findsOneWidget);
    expect(find.byType(MoviMediaCard), findsOneWidget);
    expect(find.byType(MoviPlaceholderCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
