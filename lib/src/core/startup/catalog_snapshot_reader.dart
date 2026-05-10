import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/catalog_snapshot_contracts.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';

/// Reads the local IPTV catalog state needed by startup.
///
/// This reader is intentionally local-only: it must not trigger refreshes,
/// mutate startup state, or decide navigation.
final class CatalogSnapshotReader {
  const CatalogSnapshotReader(this._localRepository);

  final IptvLocalRepository _localRepository;

  Future<CatalogSnapshot> readForSource(String sourceId) async {
    final normalizedSourceId = sourceId.trim();
    if (normalizedSourceId.isEmpty) {
      throw ArgumentError.value(sourceId, 'sourceId', 'Source id is required.');
    }

    try {
      final playlists = await _localRepository.getPlaylists(
        normalizedSourceId,
        itemLimit: 0,
      );

      if (playlists.isEmpty) {
        return CatalogSnapshot(
          sourceId: normalizedSourceId,
          exists: false,
          hasPlaylists: false,
          hasItems: false,
          mode: CatalogMode.missing,
        );
      }

      final hasItems = await _localRepository.hasAnyPlaylistItems(
        accountIds: <String>{normalizedSourceId},
      );

      return CatalogSnapshot(
        sourceId: normalizedSourceId,
        exists: true,
        hasPlaylists: true,
        hasItems: hasItems,
        mode: hasItems ? CatalogMode.cached : CatalogMode.empty,
      );
    } catch (_) {
      return CatalogSnapshot(
        sourceId: normalizedSourceId,
        exists: false,
        hasPlaylists: false,
        hasItems: false,
        mode: CatalogMode.unavailable,
      );
    }
  }
}
