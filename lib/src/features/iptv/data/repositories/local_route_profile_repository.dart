import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/iptv_owner_scope.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/iptv/domain/repositories/route_profile_repository.dart';

class LocalRouteProfileRepository implements RouteProfileRepository {
  LocalRouteProfileRepository(
    this._db, {
    required String? Function() ownerIdProvider,
  }) : _ownerIdProvider = ownerIdProvider;

  final Database _db;
  final String? Function() _ownerIdProvider;

  String get _ownerId => IptvOwnerScope.normalize(_ownerIdProvider());

  @override
  Future<List<RouteProfile>> listProfiles() async {
    final rows = await _db.query(
      'iptv_route_profiles',
      where: 'owner_id = ?',
      whereArgs: <Object?>[_ownerId],
      orderBy: 'updated_at DESC, name COLLATE NOCASE ASC',
    );

    final profiles = <RouteProfile>[
      RouteProfile.defaultProfile(ownerId: _ownerId),
    ];
    profiles.addAll(rows.map(_parseRow));
    return profiles;
  }

  @override
  Future<RouteProfile?> getProfileById(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return null;
    if (normalizedId == RouteProfile.defaultId) {
      return RouteProfile.defaultProfile(ownerId: _ownerId);
    }

    final rows = await _db.query(
      'iptv_route_profiles',
      where: 'owner_id = ? AND id = ?',
      whereArgs: <Object?>[_ownerId, normalizedId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _parseRow(rows.first);
  }

  @override
  Future<RouteProfile> saveProfile(RouteProfile profile) async {
    if (profile.id == RouteProfile.defaultId) {
      return RouteProfile.defaultProfile(ownerId: _ownerId);
    }

    final normalized = RouteProfile(
      id: profile.id.trim(),
      ownerId: _ownerId,
      name: profile.name.trim(),
      kind: profile.kind,
      proxyScheme: profile.proxyScheme?.trim(),
      proxyHost: profile.proxyHost?.trim(),
      proxyPort: profile.proxyPort,
      enabled: profile.enabled,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );

    await _db.insert('iptv_route_profiles', <String, Object?>{
      'id': normalized.id,
      'owner_id': normalized.ownerId,
      'name': normalized.name,
      'kind': normalized.kind.name,
      'proxy_scheme': normalized.proxyScheme,
      'proxy_host': normalized.proxyHost,
      'proxy_port': normalized.proxyPort,
      'enabled': normalized.enabled ? 1 : 0,
      'created_at': normalized.createdAt.millisecondsSinceEpoch,
      'updated_at': normalized.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return normalized;
  }

  @override
  Future<void> deleteProfile(String id) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty || normalizedId == RouteProfile.defaultId) return;
    await _db.delete(
      'iptv_route_profiles',
      where: 'owner_id = ? AND id = ?',
      whereArgs: <Object?>[_ownerId, normalizedId],
    );
  }

  RouteProfile _parseRow(Map<String, Object?> row) {
    final createdAtMs = (row['created_at'] as int?) ?? 0;
    final updatedAtMs = (row['updated_at'] as int?) ?? createdAtMs;
    final kindName = (row['kind'] as String?) ?? RouteProfileKind.proxy.name;
    final kind = RouteProfileKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => RouteProfileKind.proxy,
    );
    return RouteProfile(
      id: (row['id'] as String?) ?? '',
      ownerId: (row['owner_id'] as String?) ?? _ownerId,
      name: (row['name'] as String?) ?? '',
      kind: kind,
      proxyScheme: row['proxy_scheme'] as String?,
      proxyHost: row['proxy_host'] as String?,
      proxyPort: row['proxy_port'] as int?,
      enabled: ((row['enabled'] as int?) ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }
}
