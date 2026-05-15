import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

@immutable
class EntryBootStateSnapshot {
  const EntryBootStateSnapshot({
    required this.accountId,
    required this.profileSelectedLocally,
    required this.sourceSelectedLocally,
    this.selectedProfileId,
    this.selectedSourceId,
    this.firstLaunchCompletedAt,
    this.updatedAt,
  });

  final String accountId;
  final bool profileSelectedLocally;
  final bool sourceSelectedLocally;
  final String? selectedProfileId;
  final String? selectedSourceId;
  final DateTime? firstLaunchCompletedAt;
  final DateTime? updatedAt;

  bool get firstLaunchCompleted => firstLaunchCompletedAt != null;

  static const EntryBootStateSnapshot empty = EntryBootStateSnapshot(
    accountId: EntryBootStateRepository.localAccountId,
    profileSelectedLocally: false,
    sourceSelectedLocally: false,
  );
}

class EntryBootStateRepository {
  EntryBootStateRepository(this._db, {String? Function()? accountIdProvider})
    : _accountIdProvider = accountIdProvider;

  static const String table = 'entry_boot_state';
  static const String localAccountId = 'local.default';

  final Database _db;
  final String? Function()? _accountIdProvider;

  Future<EntryBootStateSnapshot> read({String? accountId}) async {
    final scopedAccountId = _resolveAccountId(accountId);
    final rows = await _db.query(
      table,
      where: 'account_id = ?',
      whereArgs: <Object?>[scopedAccountId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return EntryBootStateSnapshot(
        accountId: scopedAccountId,
        profileSelectedLocally: false,
        sourceSelectedLocally: false,
      );
    }
    return _mapRow(rows.first);
  }

  Future<void> confirmProfileSelected({
    required String profileId,
    String? accountId,
  }) async {
    await _upsertState(
      accountId: _resolveAccountId(accountId),
      profileSelectedLocally: true,
      selectedProfileId: profileId,
    );
  }

  Future<void> clearProfileSelection({String? accountId}) async {
    await _upsertState(
      accountId: _resolveAccountId(accountId),
      profileSelectedLocally: false,
      selectedProfileId: null,
    );
  }

  Future<void> confirmSourceSelected({
    required String sourceId,
    String? accountId,
  }) async {
    await _upsertState(
      accountId: _resolveAccountId(accountId),
      sourceSelectedLocally: true,
      selectedSourceId: sourceId,
    );
  }

  Future<void> clearSourceSelection({String? accountId}) async {
    await _upsertState(
      accountId: _resolveAccountId(accountId),
      sourceSelectedLocally: false,
      selectedSourceId: null,
    );
  }

  Future<void> markFirstLaunchCompleted({String? accountId}) async {
    final scopedAccountId = _resolveAccountId(accountId);
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    final existing = await read(accountId: scopedAccountId);
    await _db.insert(table, <String, Object?>{
      'account_id': scopedAccountId,
      'profile_selected_locally': existing.profileSelectedLocally ? 1 : 0,
      'source_selected_locally': existing.sourceSelectedLocally ? 1 : 0,
      'selected_profile_id': existing.selectedProfileId,
      'selected_source_id': existing.selectedSourceId,
      'first_launch_completed_at': nowEpochMs,
      'updated_at': nowEpochMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _upsertState({
    required String accountId,
    bool? profileSelectedLocally,
    bool? sourceSelectedLocally,
    Object? selectedProfileId = _sentinel,
    Object? selectedSourceId = _sentinel,
  }) async {
    final existing = await read(accountId: accountId);
    final nowEpochMs = DateTime.now().millisecondsSinceEpoch;
    await _db.insert(table, <String, Object?>{
      'account_id': accountId,
      'profile_selected_locally':
          profileSelectedLocally ?? existing.profileSelectedLocally ? 1 : 0,
      'source_selected_locally':
          sourceSelectedLocally ?? existing.sourceSelectedLocally ? 1 : 0,
      'selected_profile_id': identical(selectedProfileId, _sentinel)
          ? existing.selectedProfileId
          : _normalizeNullable(selectedProfileId as String?),
      'selected_source_id': identical(selectedSourceId, _sentinel)
          ? existing.selectedSourceId
          : _normalizeNullable(selectedSourceId as String?),
      'first_launch_completed_at': existing.firstLaunchCompletedAt
          ?.millisecondsSinceEpoch,
      'updated_at': nowEpochMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  EntryBootStateSnapshot _mapRow(Map<String, Object?> row) {
    final firstLaunchMs = row['first_launch_completed_at'] as int?;
    final updatedAtMs = row['updated_at'] as int?;
    return EntryBootStateSnapshot(
      accountId: (row['account_id'] as String?) ??
          localAccountId,
      profileSelectedLocally: _toBool(row['profile_selected_locally']),
      sourceSelectedLocally: _toBool(row['source_selected_locally']),
      selectedProfileId: _normalizeNullable(row['selected_profile_id'] as String?),
      selectedSourceId: _normalizeNullable(row['selected_source_id'] as String?),
      firstLaunchCompletedAt: firstLaunchMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(firstLaunchMs),
      updatedAt: updatedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }

  String _resolveAccountId(String? accountId) {
    final explicit = _normalizeNullable(accountId);
    if (explicit != null) return explicit;
    final derived = _normalizeNullable(_accountIdProvider?.call());
    if (derived != null) return derived;
    return localAccountId;
  }

  static bool _toBool(Object? raw) {
    if (raw is int) return raw != 0;
    if (raw is bool) return raw;
    return false;
  }

  static String? _normalizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static const Object _sentinel = Object();
}
