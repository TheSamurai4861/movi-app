import 'package:sqflite/sqflite.dart';

import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/core/storage/repositories/iptv/iptv_storage_tables.dart';

/// Persists IPTV account records and their account-scoped cleanup.
///
/// The public repository keeps its existing API, while this store isolates the
/// raw SQLite mapping logic for Xtream and Stalker accounts.
class IptvAccountStore {
  IptvAccountStore(this._db);

  final Database _db;

  Future<void> saveAccount({
    required String ownerId,
    required XtreamAccount account,
  }) async {
    await _db.insert(IptvStorageTables.accounts, <String, Object?>{
      'owner_id': ownerId,
      'account_id': account.id,
      'alias': account.alias,
      'endpoint': account.endpoint.toRawUrl(),
      'username': account.username,
      'status': account.status.name,
      'expiration': account.expirationDate?.millisecondsSinceEpoch,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'last_error': account.lastError,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<XtreamAccount>> getAccounts({String? ownerId}) async {
    final rows = await _db.query(
      IptvStorageTables.accounts,
      where: ownerId == null ? null : 'owner_id = ?',
      whereArgs: ownerId == null ? null : <Object?>[ownerId],
    );
    return rows.map(_parseAccountRow).toList(growable: false);
  }

  Future<void> removeAccount(String id, {String? ownerId}) async {
    await _db.delete(
      IptvStorageTables.accounts,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
    await _deleteAssociatedAccountData(id, ownerId: ownerId);
  }

  Future<void> saveStalkerAccount({
    required String ownerId,
    required StalkerAccount account,
  }) async {
    await _db.insert(
      IptvStorageTables.stalkerAccounts,
      <String, Object?>{
        'owner_id': ownerId,
        'account_id': account.id,
        'alias': account.alias,
        'endpoint': account.endpoint.toRawUrl(),
        'mac_address': account.macAddress,
        'username': account.username,
        'token': account.token,
        'status': account.status.name,
        'expiration': account.expirationDate?.millisecondsSinceEpoch,
        'created_at': account.createdAt.millisecondsSinceEpoch,
        'last_error': account.lastError,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StalkerAccount>> getStalkerAccounts({String? ownerId}) async {
    final rows = await _db.query(
      IptvStorageTables.stalkerAccounts,
      where: ownerId == null ? null : 'owner_id = ?',
      whereArgs: ownerId == null ? null : <Object?>[ownerId],
    );
    return rows.map(_parseStalkerAccountRow).toList(growable: false);
  }

  Future<StalkerAccount?> getStalkerAccount(String id, {String? ownerId}) async {
    final rows = await _db.query(
      IptvStorageTables.stalkerAccounts,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseStalkerAccountRow(rows.first);
  }

  Future<void> removeStalkerAccount(String id, {String? ownerId}) async {
    await _db.delete(
      IptvStorageTables.stalkerAccounts,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
    await _deleteAssociatedAccountData(id, ownerId: ownerId);
  }

  Future<Set<String>> resolveAccountIds(
    Set<String>? requestedAccountIds,
    {
    String? ownerId,
  }) async {
    final xtreamAccounts = await getAccounts(ownerId: ownerId);
    final stalkerAccounts = await getStalkerAccounts(ownerId: ownerId);
    final ids = <String>{
      ...xtreamAccounts.map((account) => account.id),
      ...stalkerAccounts.map((account) => account.id),
    };

    if (requestedAccountIds == null) {
      return ids;
    }
    if (requestedAccountIds.isEmpty) {
      return <String>{};
    }

    ids.removeWhere((id) => !requestedAccountIds.contains(id));
    return ids;
  }

  Future<void> _deleteAssociatedAccountData(String id, {String? ownerId}) async {
    await _db.delete(
      IptvStorageTables.playlistItems,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
    await _db.delete(
      IptvStorageTables.playlists,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
    await _db.delete(
      IptvStorageTables.playlistsLegacy,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
    await _db.delete(
      IptvStorageTables.episodes,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
    await _db.delete(
      IptvStorageTables.playlistSettings,
      where: _withOptionalOwnerFilter('account_id = ?', ownerId),
      whereArgs: _withOptionalOwnerArgs(ownerId, <Object?>[id]),
    );
  }

  String _withOptionalOwnerFilter(String baseWhere, String? ownerId) {
    if (ownerId == null) {
      return baseWhere;
    }
    return 'owner_id = ? AND $baseWhere';
  }

  List<Object?> _withOptionalOwnerArgs(String? ownerId, List<Object?> args) {
    if (ownerId == null) {
      return args;
    }
    return <Object?>[ownerId, ...args];
  }

  XtreamAccount _parseAccountRow(Map<String, Object?> row) {
    final String id = (row['account_id'] as String?) ?? '';
    final String alias = (row['alias'] as String?) ?? '';
    final String endpointRaw = (row['endpoint'] as String?) ?? '';
    final String username = (row['username'] as String?) ?? '';
    final String statusStr =
        (row['status'] as String?) ?? XtreamAccountStatus.pending.name;
    final int createdAtMs = (row['created_at'] as int?) ?? 0;
    final int? expirationMs = row['expiration'] as int?;
    final String? lastError = row['last_error'] as String?;

    final XtreamAccountStatus status = XtreamAccountStatus.values.firstWhere(
      (candidate) => candidate.name == statusStr,
      orElse: () => XtreamAccountStatus.pending,
    );

    return XtreamAccount(
      id: id,
      alias: alias,
      endpoint: XtreamEndpoint.parse(endpointRaw),
      username: username,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      expirationDate: expirationMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
          : null,
      lastError: lastError,
    );
  }

  StalkerAccount _parseStalkerAccountRow(Map<String, Object?> row) {
    final String id = (row['account_id'] as String?) ?? '';
    final String alias = (row['alias'] as String?) ?? '';
    final String endpointRaw = (row['endpoint'] as String?) ?? '';
    final String macAddress = (row['mac_address'] as String?) ?? '';
    final String? username = row['username'] as String?;
    final String? token = row['token'] as String?;
    final String statusStr =
        (row['status'] as String?) ?? StalkerAccountStatus.pending.name;
    final int createdAtMs = (row['created_at'] as int?) ?? 0;
    final int? expirationMs = row['expiration'] as int?;
    final String? lastError = row['last_error'] as String?;

    final StalkerAccountStatus status = StalkerAccountStatus.values.firstWhere(
      (candidate) => candidate.name == statusStr,
      orElse: () => StalkerAccountStatus.pending,
    );

    return StalkerAccount(
      id: id,
      alias: alias,
      endpoint: StalkerEndpoint.parse(endpointRaw),
      macAddress: macAddress,
      username: username,
      token: token,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      expirationDate: expirationMs != null
          ? DateTime.fromMillisecondsSinceEpoch(expirationMs)
          : null,
      lastError: lastError,
    );
  }
}
