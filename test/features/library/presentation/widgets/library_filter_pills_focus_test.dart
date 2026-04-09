import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    await tester.pump();
  }

  testWidgets('first filter handles left/down focus routing', (tester) async {
    final firstFilterFocusNode = FocusNode();
    final artistsFilterFocusNode = FocusNode();
    var sidebarRequested = 0;
    var firstPlaylistRequested = 0;
    var searchRequested = 0;

    await pumpFilterBar(
      tester,
      firstFilterFocusNode: firstFilterFocusNode,
      artistsFilterFocusNode: artistsFilterFocusNode,
      onSidebarRequested: () => sidebarRequested++,
      onFirstPlaylistRequested: () => firstPlaylistRequested++,
      onSearchRequested: () => searchRequested++,
    );

    firstFilterFocusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(sidebarRequested, 1);
    expect(firstPlaylistRequested, 1);
    expect(searchRequested, 0);

    firstFilterFocusNode.dispose();
    artistsFilterFocusNode.dispose();
  });

  testWidgets('artists filter routes right to search action', (tester) async {
    final firstFilterFocusNode = FocusNode();
    final artistsFilterFocusNode = FocusNode();
    var sidebarRequested = 0;
    var firstPlaylistRequested = 0;
    var searchRequested = 0;

    await pumpFilterBar(
      tester,
      firstFilterFocusNode: firstFilterFocusNode,
      artistsFilterFocusNode: artistsFilterFocusNode,
      onSidebarRequested: () => sidebarRequested++,
      onFirstPlaylistRequested: () => firstPlaylistRequested++,
      onSearchRequested: () => searchRequested++,
    );

    artistsFilterFocusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(searchRequested, 1);
    expect(sidebarRequested, 0);
    expect(firstPlaylistRequested, 0);

    firstFilterFocusNode.dispose();
    artistsFilterFocusNode.dispose();
  });
}
