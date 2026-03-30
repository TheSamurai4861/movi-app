import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';

void main() {
  testWidgets(
    'LibraryPlaylistCard keeps playlist metadata visible when artwork is missing',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LibraryPlaylistCard(
                title: 'Ma playlist',
                itemCount: 3,
                type: LibraryPlaylistType.userPlaylist,
                isPinned: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ma playlist'), findsOneWidget);
      expect(find.textContaining('Playlist'), findsOneWidget);
      expect(find.textContaining('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'LibraryPlaylistCard uses an explicit placeholder for actor cards without photo',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LibraryPlaylistCard(
                title: 'Acteur',
                itemCount: 0,
                type: LibraryPlaylistType.actor,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MoviPlaceholderCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
