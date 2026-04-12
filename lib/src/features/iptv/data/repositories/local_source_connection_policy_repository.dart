import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/iptv_owner_scope.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/iptv/domain/repositories/source_connection_policy_repository.dart';

class LocalSourceConnectionPolicyRepository
    implements SourceConnectionPolicyRepository {
  LocalSourceConnectionPolicyRepository(
    this._db, {
    required String? Function() ownerIdProvider,
  }) : _ownerIdProvider = ownerIdProvider;

  final Database _db;
  final String? Function() _ownerIdProvider;

  String get _ownerId => IptvOwnerScope.normalize(_ownerIdProvider());

  @override
  Future<SourceConnectionPolicy?> getPolicy({
    required String accountId,
    required SourceKind sourceKind,
  }) async {
    final rows = await _db.query(
      'iptv_source_connection_policies',
      where: 'owner_id = ? AND account_id = ? AND source_kind = ?',
      whereArgs: <Object?>[_ownerId, accountId, sourceKind.name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseRow(rows.first);
  }

  @override
  Future<SourceConnectionPolicy> savePolicy(
    SourceConnectionPolicy policy,
  ) async {
    final normalized = SourceConnectionPolicy(
      ownerId: _ownerId,
      accountId: policy.accountId.trim(),
      sourceKind: policy.sourceKind,
      preferredRouteProfileId: policy.preferredRouteProfileId.trim().isEmpty
          ? RouteProfile.defaultId
          : policy.preferredRouteProfileId.trim(),
      fallbackRouteProfileIds: policy.fallbackRouteProfileIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      lastWorkingRouteProfileId: policy.lastWorkingRouteProfileId?.trim(),
      updatedAt: policy.updatedAt,
    );

    await _db.insert(
      'iptv_source_connection_policies',
      <String, Object?>{
        'owner_id': normalized.ownerId,
        'account_id': normalized.accountId,
        'source_kind': normalized.sourceKind.name,
        'preferred_route_profile_id': normalized.preferredRouteProfileId,
        'fallback_route_profile_ids_json': jsonEncode(
          normalized.fallbackRouteProfileIds,
        ),
        'last_working_route_profile_id': normalized.lastWorkingRouteProfileId,
        'updated_at': normalized.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return normalized;
  }

  @override
  Future<void> deletePolicy({
    required String accountId,
    required SourceKind sourceKind,
  }) async {
    await _db.delete(
      'iptv_source_connection_policies',
      where: 'owner_id = ? AND account_id = ? AND source_kind = ?',
      whereArgs: <Object?>[_ownerId, accountId, sourceKind.name],
    );
  }

  SourceConnectionPolicy _parseRow(Map<String, Object?> row) {
    final updatedAtMs = (row['updated_at'] as int?) ?? 0;
    final sourceKindName =
        (row['source_kind'] as String?) ?? SourceKind.xtream.name;
    final sourceKind = SourceKind.values.firstWhere(
      (candidate) => candidate.name == sourceKindName,
      orElse: () => SourceKind.xtream,
    );
    final fallbackRaw =
        (row['fallback_route_profile_ids_json'] as String?) ?? '[]';
    final decoded = jsonDecode(fallbackRaw);
    final fallbackIds = decoded is List
        ? decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return SourceConnectionPolicy(
      ownerId: (row['owner_id'] as String?) ?? _ownerId,
      accountId: (row['account_id'] as String?) ?? '',
      sourceKind: sourceKind,
      preferredRouteProfileId:
          (row['preferred_route_profile_id'] as String?)?.trim().isNotEmpty ==
              true
          ? (row['preferred_route_profile_id'] as String).trim()
          : RouteProfile.defaultId,
      fallbackRouteProfileIds: fallbackIds,
      lastWorkingRouteProfileId:
          (row['last_working_route_profile_id'] as String?)?.trim(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }
}
