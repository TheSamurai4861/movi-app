import '../../domain/entities/xtream_account.dart';
import '../../domain/entities/xtream_catalog_snapshot.dart';
import '../../domain/entities/xtream_playlist.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../../domain/value_objects/xtream_endpoint.dart';
import '../datasources/xtream_cache_data_source.dart';
import '../datasources/xtream_remote_data_source.dart';
import '../../application/services/playlist_mapper.dart';

class IptvRepositoryImpl implements IptvRepository {
  IptvRepositoryImpl(this._remote, this._cache, this._playlistMapper);

  final XtreamRemoteDataSource _remote;
  final XtreamCacheDataSource _cache;
  final PlaylistMapper _playlistMapper;

  @override
  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  }) async {
    final auth = await _remote.authenticate(
      endpoint: endpoint,
      username: username,
      password: password,
    );
    final status = auth.isAuthorized
        ? XtreamAccountStatus.active
        : XtreamAccountStatus.error;
    final account = XtreamAccount(
      id: _buildAccountId(endpoint, username),
      alias: alias,
      endpoint: endpoint,
      username: username,
      password: password,
      status: status,
      createdAt: DateTime.now(),
      expirationDate: auth.expiration,
      lastError: auth.isAuthorized ? null : auth.message,
    );
    await _cache.saveAccount(account);
    if (!auth.isAuthorized) {
      throw Exception('Xtream authentication failed: ${auth.message}');
    }
    return account;
  }

  @override
  Future<List<XtreamAccount>> getAccounts() {
    return _cache.getAccounts();
  }

  @override
  Future<void> removeSource(String accountId) {
    return _cache.removeAccount(accountId);
  }

  @override
  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId) async {
    final account = await _cache.getAccount(accountId);
    if (account == null) {
      throw Exception('Unknown Xtream account $accountId');
    }

    final request = XtreamAccountRequest(
      endpoint: account.endpoint,
      username: account.username,
      password: account.password,
    );

    final moviesCategories = await _remote.getVodCategories(request);
    final seriesCategories = await _remote.getSeriesCategories(request);
    final movies = await _remote.getVodStreams(request);
    final series = await _remote.getSeries(request);

    final playlists = _playlistMapper.buildPlaylists(
      accountId: accountId,
      movieCategories: moviesCategories,
      movieStreams: movies,
      seriesCategories: seriesCategories,
      seriesStreams: series,
    );

    await _cache.savePlaylists(accountId, playlists);

    final snapshot = XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: movies.length,
      seriesCount: series.length,
    );
    await _cache.saveSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) {
    return _cache.getPlaylists(accountId);
  }

  String _buildAccountId(XtreamEndpoint endpoint, String username) {
    final normalized = '${endpoint.baseUrl}_${username.toLowerCase()}';
    return normalized;
  }
}
