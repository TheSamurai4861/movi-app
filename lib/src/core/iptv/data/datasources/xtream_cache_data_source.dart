import '../../domain/entities/xtream_account.dart';
import '../../domain/entities/xtream_catalog_snapshot.dart';
import '../../domain/entities/xtream_playlist.dart';
import '../../../storage/repositories/iptv_local_repository.dart';
import '../../../storage/repositories/content_cache_repository.dart';
import '../../../storage/services/cache_policy.dart';

class XtreamCacheDataSource {
  XtreamCacheDataSource(this._localRepository, this._cacheRepository);

  final IptvLocalRepository _localRepository;
  final ContentCacheRepository _cacheRepository;

  // Default TTL for snapshots: 6 hours
  static const CachePolicy snapshotPolicy = CachePolicy(
    ttl: Duration(hours: 6),
  );

  Future<List<XtreamAccount>> getAccounts() => _localRepository.getAccounts();

  Future<void> saveAccount(XtreamAccount account) =>
      _localRepository.saveAccount(account);

  Future<void> removeAccount(String id) => _localRepository.removeAccount(id);

  Future<XtreamAccount?> getAccount(String id) async {
    final accounts = await _localRepository.getAccounts();
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<void> saveSnapshot(XtreamCatalogSnapshot snapshot) async {
    await _cacheRepository.put(
      key: 'xtream_snapshot_${snapshot.accountId}',
      type: 'xtream_snapshot',
      payload: {
        'movieCount': snapshot.movieCount,
        'seriesCount': snapshot.seriesCount,
        'updatedAt': snapshot.lastSyncAt.toIso8601String(),
        'error': snapshot.lastError,
      },
    );
  }

  Future<XtreamCatalogSnapshot?> getSnapshot(
    String accountId, {
    CachePolicy? policy,
  }) async {
    final key = 'xtream_snapshot_$accountId';
    final data = policy == null
        ? await _cacheRepository.get(key)
        : await _cacheRepository.getWithPolicy(key, policy);
    if (data == null) return null;
    return XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt:
          DateTime.tryParse(data['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      movieCount: data['movieCount'] as int? ?? 0,
      seriesCount: data['seriesCount'] as int? ?? 0,
      lastError: data['error'] as String?,
    );
  }

  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) => _localRepository.savePlaylists(accountId, playlists);

  Future<List<XtreamPlaylist>> getPlaylists(String accountId) =>
      _localRepository.getPlaylists(accountId);
}
