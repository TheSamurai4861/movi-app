import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/catalog_snapshot_reader.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/catalog_snapshot_contracts.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';

void main() {
  group('CatalogMode', () {
    test('only fresh cached and stale can open Home', () {
      expect(CatalogMode.fresh.canOpenHome, isTrue);
      expect(CatalogMode.cached.canOpenHome, isTrue);
      expect(CatalogMode.stale.canOpenHome, isTrue);

      expect(CatalogMode.missing.canOpenHome, isFalse);
      expect(CatalogMode.empty.canOpenHome, isFalse);
      expect(CatalogMode.unavailable.canOpenHome, isFalse);
    });
  });

  group('CatalogSnapshot', () {
    test('exposes Home readiness from its mode', () {
      for (final mode in <CatalogMode>[
        CatalogMode.fresh,
        CatalogMode.cached,
        CatalogMode.stale,
      ]) {
        final snapshot = CatalogSnapshot(
          sourceId: 'source_1',
          exists: true,
          hasPlaylists: true,
          hasItems: true,
          mode: mode,
        );

        expect(snapshot.canOpenHome, isTrue);
      }

      for (final mode in <CatalogMode>[
        CatalogMode.missing,
        CatalogMode.empty,
        CatalogMode.unavailable,
      ]) {
        final snapshot = CatalogSnapshot(
          sourceId: 'source_1',
          exists: mode == CatalogMode.empty,
          hasPlaylists: mode == CatalogMode.empty,
          hasItems: false,
          mode: mode,
        );

        expect(snapshot.canOpenHome, isFalse);
      }
    });

    test('keeps snapshot age nullable until freshness is available', () {
      const snapshot = CatalogSnapshot(
        sourceId: 'source_1',
        exists: true,
        hasPlaylists: true,
        hasItems: true,
        mode: CatalogMode.cached,
      );

      expect(snapshot.age, isNull);
    });

    test('can represent a stale but still exploitable snapshot', () {
      const snapshot = CatalogSnapshot(
        sourceId: 'source_1',
        exists: true,
        hasPlaylists: true,
        hasItems: true,
        mode: CatalogMode.stale,
        age: Duration(days: 2),
      );

      expect(snapshot.canOpenHome, isTrue);
      expect(snapshot.age, const Duration(days: 2));
    });
  });

  group('CatalogSnapshotReader', () {
    test('maps playlists with items to cached and openable', () async {
      final repository = _FakeIptvLocalRepository(
        playlists: <XtreamPlaylist>[_playlist()],
        hasItems: true,
      );
      final reader = CatalogSnapshotReader(repository);

      final snapshot = await reader.readForSource(' source_1 ');

      expect(snapshot.sourceId, 'source_1');
      expect(snapshot.exists, isTrue);
      expect(snapshot.hasPlaylists, isTrue);
      expect(snapshot.hasItems, isTrue);
      expect(snapshot.mode, CatalogMode.cached);
      expect(snapshot.canOpenHome, isTrue);
      expect(repository.requestedAccountId, 'source_1');
      expect(repository.requestedItemLimit, 0);
      expect(repository.requestedItemAccountIds, <String>{'source_1'});
    });

    test('maps playlists without items to empty and not openable', () async {
      final repository = _FakeIptvLocalRepository(
        playlists: <XtreamPlaylist>[_playlist()],
        hasItems: false,
      );
      final reader = CatalogSnapshotReader(repository);

      final snapshot = await reader.readForSource('source_1');

      expect(snapshot.exists, isTrue);
      expect(snapshot.hasPlaylists, isTrue);
      expect(snapshot.hasItems, isFalse);
      expect(snapshot.mode, CatalogMode.empty);
      expect(snapshot.canOpenHome, isFalse);
    });

    test('maps missing playlists to missing and skips item lookup', () async {
      final repository = _FakeIptvLocalRepository(
        playlists: const <XtreamPlaylist>[],
        hasItems: true,
      );
      final reader = CatalogSnapshotReader(repository);

      final snapshot = await reader.readForSource('source_1');

      expect(snapshot.exists, isFalse);
      expect(snapshot.hasPlaylists, isFalse);
      expect(snapshot.hasItems, isFalse);
      expect(snapshot.mode, CatalogMode.missing);
      expect(snapshot.canOpenHome, isFalse);
      expect(repository.itemLookupCount, 0);
    });

    test('maps local read failures to unavailable', () async {
      final repository = _FakeIptvLocalRepository(
        playlists: const <XtreamPlaylist>[],
        hasItems: false,
        throwOnPlaylists: true,
      );
      final reader = CatalogSnapshotReader(repository);

      final snapshot = await reader.readForSource('source_1');

      expect(snapshot.exists, isFalse);
      expect(snapshot.hasPlaylists, isFalse);
      expect(snapshot.hasItems, isFalse);
      expect(snapshot.mode, CatalogMode.unavailable);
      expect(snapshot.canOpenHome, isFalse);
    });
  });
}

XtreamPlaylist _playlist() {
  return const XtreamPlaylist(
    id: 'pl_movies',
    accountId: 'source_1',
    title: 'Films',
    type: XtreamPlaylistType.movies,
    items: <Never>[],
  );
}

final class _FakeIptvLocalRepository implements IptvLocalRepository {
  _FakeIptvLocalRepository({
    required this.playlists,
    required this.hasItems,
    this.throwOnPlaylists = false,
  });

  final List<XtreamPlaylist> playlists;
  final bool hasItems;
  final bool throwOnPlaylists;

  String? requestedAccountId;
  int? requestedItemLimit;
  Set<String>? requestedItemAccountIds;
  int itemLookupCount = 0;

  @override
  Future<List<XtreamPlaylist>> getPlaylists(
    String accountId, {
    int? itemLimit,
  }) async {
    requestedAccountId = accountId;
    requestedItemLimit = itemLimit;
    if (throwOnPlaylists) {
      throw StateError('read failed');
    }
    return playlists;
  }

  @override
  Future<bool> hasAnyPlaylistItems({Set<String>? accountIds}) async {
    itemLookupCount += 1;
    requestedItemAccountIds = accountIds;
    return hasItems;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
