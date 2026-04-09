import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';

void main() {
  Future<void> pumpFilterBar(
    WidgetTester tester, {
    required FocusNode firstFilterFocusNode,
    required FocusNode artistsFilterFocusNode,
    required VoidCallback onSidebarRequested,
    required VoidCallback onFirstPlaylistRequested,
    required VoidCallback onSearchRequested,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LibraryFilterPills(
              activeFilter: null,
              firstFilterFocusNode: firstFilterFocusNode,
              artistsFilterFocusNode: artistsFilterFocusNode,
              onRequestSidebarFocus: onSidebarRequested,
              onRequestFirstPlaylistFocus: onFirstPlaylistRequested,
              onRequestSearchActionFocus: onSearchRequested,
              onFilterChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('library filter pills render', (tester) async {
    final firstFilterFocusNode = FocusNode();
    final artistsFilterFocusNode = FocusNode();

    await pumpFilterBar(
      tester,
      firstFilterFocusNode: firstFilterFocusNode,
      artistsFilterFocusNode: artistsFilterFocusNode,
      onSidebarRequested: () {},
      onFirstPlaylistRequested: () {},
      onSearchRequested: () {},
    );

    expect(find.byType(LibraryFilterPills), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);

    firstFilterFocusNode.dispose();
    artistsFilterFocusNode.dispose();
  });
}
