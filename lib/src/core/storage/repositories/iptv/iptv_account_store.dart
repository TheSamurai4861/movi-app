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

  Future<void> saveAccount(XtreamAccount account) async {
    await _db.insert(IptvStorageTables.accounts, <String, Object?>{
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

  Future<List<XtreamAccount>> getAccounts() async {
    final rows = await _db.query(IptvStorageTables.accounts);
    return rows.map(_parseAccountRow).toList(growable: false);
  }

  Future<void> removeAccount(String id) async {
    await _db.delete(
      IptvStorageTables.accounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _deleteAssociatedAccountData(id);
  }

  Future<void> saveStalkerAccount(StalkerAccount account) async {
    await _db.insert(
      IptvStorageTables.stalkerAccounts,
      <String, Object?>{
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

  Future<List<StalkerAccount>> getStalkerAccounts() async {
    final rows = await _db.query(IptvStorageTables.stalkerAccounts);
    return rows.map(_parseStalkerAccountRow).toList(growable: false);
  }

  Future<StalkerAccount?> getStalkerAccount(String id) async {
    final rows = await _db.query(
      IptvStorageTables.stalkerAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseStalkerAccountRow(rows.first);
  }

  Future<void> removeStalkerAccount(String id) async {
    await _db.delete(
      IptvStorageTables.stalkerAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _deleteAssociatedAccountData(id);
  }

  Future<Set<String>> resolveAccountIds(
    Set<String>? requestedAccountIds,
  ) async {
    final xtreamAccounts = await getAccounts();
    final stalkerAccounts = await getStalkerAccounts();
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

  Future<void> _deleteAssociatedAccountData(String id) async {
    await _db.delete(
      IptvStorageTables.playlistItems,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      IptvStorageTables.playlists,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      IptvStorageTables.playlistsLegacy,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      IptvStorageTables.episodes,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await _db.delete(
      IptvStorageTables.playlistSettings,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
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
