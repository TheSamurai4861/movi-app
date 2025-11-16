import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/features/iptv/application/services/playlist_mapper.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';

class IptvRepositoryImpl implements IptvRepository {
  IptvRepositoryImpl(
    this._local,
    this._vault,
    this._remote,
    this._mapper,
    this._cache,
  );

  final IptvLocalRepository _local;
  final CredentialsVault _vault;
  final XtreamRemoteDataSource _remote;
  final PlaylistMapper _mapper;
  final XtreamCacheDataSource _cache;

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
    final id = '${endpoint.host}_$username'.toLowerCase();
    final status = auth.isAuthorized
        ? XtreamAccountStatus.active
        : XtreamAccountStatus.error;
    final account = XtreamAccount(
      id: id,
      alias: alias,
      endpoint: endpoint,
      username: username,
      status: status,
      createdAt: DateTime.now(),
      expirationDate: auth.expiration,
      lastError: auth.isAuthorized ? null : auth.message,
    );
    await _local.saveAccount(account);
    await _vault.storePassword(id, password);
    if (!auth.isAuthorized) {
      throw AuthFailure('Xtream authentication failed: ${auth.message}');
    }
    return account;
  }

  @override
  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId) async {
    final accounts = await _local.getAccounts();
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () =>
          throw AccountNotFoundFailure('Unknown Xtream account $accountId'),
    );

    String? password = await _vault.readPassword(accountId);
    if (password == null || password.isEmpty) {
      final hostKey = '${account.endpoint.host}_${account.username}'
          .toLowerCase();
      if (hostKey != accountId) {
        password = await _vault.readPassword(hostKey);
      }
    }
    if (password == null || password.isEmpty) {
      final rawUrlKey = '${account.endpoint.toRawUrl()}_${account.username}'
          .toLowerCase();
      if (rawUrlKey != accountId) {
        password = await _vault.readPassword(rawUrlKey);
      }
    }
    if (password == null || password.isEmpty) {
      throw MissingCredentialsFailure('Missing credentials for $accountId');
    }

    final request = XtreamAccountRequest(
      endpoint: account.endpoint,
      username: account.username,
      password: password,
    );

    final moviesCategories = await _remote.getVodCategories(request);
    final seriesCategories = await _remote.getSeriesCategories(request);
    final movies = await _remote.getVodStreams(request);
    final series = await _remote.getSeries(request);

    final playlists = _mapper.buildPlaylists(
      accountId: accountId,
      movieCategories: moviesCategories,
      movieStreams: movies,
      seriesCategories: seriesCategories,
      seriesStreams: series,
    );

    await _local.savePlaylists(accountId, playlists);

    final movieCount = movies.length;
    final seriesCount = series.length;
    final snapshot = XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: movieCount,
      seriesCount: seriesCount,
    );
    await _cache.saveSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) {
    return _local.getPlaylists(accountId);
  }
}
