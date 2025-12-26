import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_catalog_snapshot.dart';

const Duration kStalkerPlaylistTtl = Duration(hours: 5);

class StalkerCacheDataSource {
  StalkerCacheDataSource(this._cache);

  final ContentCacheRepository _cache;

  static final CachePolicy snapshotPolicy = CachePolicy(ttl: kStalkerPlaylistTtl);

  static const String _cacheType = 'stalker_snapshot';

  String _keyFor(String accountId) => 'stalker_snapshot_$accountId';

  Future<void> saveSnapshot(StalkerCatalogSnapshot snapshot) async {
    final map = <String, dynamic>{
      'accountId': snapshot.accountId,
      'lastSyncAt': snapshot.lastSyncAt.toIso8601String(),
      'movieCount': snapshot.movieCount,
      'seriesCount': snapshot.seriesCount,
      'lastError': snapshot.lastError,
    };
    await _cache.put(
      key: _keyFor(snapshot.accountId),
      type: _cacheType,
      payload: map,
    );
  }

  Future<StalkerCatalogSnapshot?> getSnapshot(
    String accountId, {
    CachePolicy? policy,
  }) async {
    final data = await _cache.get(
      _keyFor(accountId),
      policy: policy ?? snapshotPolicy,
    );
    if (data == null) return null;
    final String? rawDate = data['lastSyncAt'] as String?;
    final DateTime? parsed = rawDate != null
        ? DateTime.tryParse(rawDate)
        : null;
    if (parsed == null) return null;
    return StalkerCatalogSnapshot(
      accountId: data['accountId'] as String? ?? accountId,
      lastSyncAt: parsed,
      movieCount: (data['movieCount'] as num?)?.toInt() ?? 0,
      seriesCount: (data['seriesCount'] as num?)?.toInt() ?? 0,
      lastError: data['lastError'] as String?,
    );
  }
}

