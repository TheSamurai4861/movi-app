import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._db);

  static const String table = 'local_profiles';
  static const String defaultAccountId = 'local.default';

  final Database _db;

  @override
  Future<List<Profile>> getProfiles({
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _normalizeAccountId(accountId);
    final rows = await _db.query(
      table,
      where: resolvedAccountId == null ? null : 'account_id = ?',
      whereArgs: resolvedAccountId == null ? null : [resolvedAccountId],
      orderBy: 'COALESCE(created_at, updated_at) ASC, id ASC',
    );
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<Profile> createProfile({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty.');
    }

    final now = DateTime.now();
    final profile = Profile(
      id: _nextLocalId(),
      accountId: _normalizeAccountId(accountId) ?? defaultAccountId,
      name: trimmedName,
      color: color,
      avatarUrl: _normalizeNullable(avatarUrl),
      createdAt: now,
    );
    await upsertProfile(profile);
    return profile;
  }

  @override
  Future<Profile> updateProfile({
    required String profileId,
    String? name,
    int? color,
    String? avatarUrl,
    bool? isKid,
    Object? pegiLimit = ProfileRepository.noChange,
    bool? diagnostics,
  }) async {
    final current = await findById(profileId);
    if (current == null) {
      throw StateError('Local profile not found: $profileId');
    }

    final next = current.copyWith(
      name: name?.trim().isEmpty == true ? current.name : name?.trim(),
      color: color,
      avatarUrl: avatarUrl,
      isKid: isKid,
      pegiLimit: identical(pegiLimit, ProfileRepository.noChange)
          ? current.pegiLimit
          : pegiLimit as int?,
    );
    await upsertProfile(next);
    return next;
  }

  @override
  Future<void> deleteProfile(String profileId, {bool? diagnostics}) async {
    await _db.delete(table, where: 'id = ?', whereArgs: [profileId]);
  }

  @override
  Future<Profile> getOrCreateDefaultProfile({
    String? accountId,
    bool? diagnostics,
  }) async {
    final profiles = await getProfiles(accountId: accountId);
    if (profiles.isNotEmpty) return profiles.first;
    return createProfile(
      name: 'Profile',
      color: 0xFF2160AB,
      accountId: accountId,
    );
  }

  Future<Profile?> findById(String profileId) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  Future<void> upsertProfile(Profile profile) async {
    final now = DateTime.now();
    await _db.insert(
      table,
      _toRow(profile, updatedAt: now),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertProfiles(Iterable<Profile> profiles) async {
    final batch = _db.batch();
    final now = DateTime.now();
    for (final profile in profiles) {
      batch.insert(
        table,
        _toRow(profile, updatedAt: now),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _toRow(Profile profile, {required DateTime updatedAt}) {
    return <String, Object?>{
      'id': profile.id,
      'account_id': _normalizeAccountId(profile.accountId) ?? defaultAccountId,
      'name': profile.name.trim(),
      'color': profile.color,
      'avatar_url': _normalizeNullable(profile.avatarUrl),
      'created_at': profile.createdAt?.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_kid': profile.isKid ? 1 : 0,
      'pegi_limit': profile.pegiLimit,
      'has_pin': profile.hasPin ? 1 : 0,
    };
  }

  Profile _mapRow(Map<String, Object?> row) {
    return Profile(
      id: row['id']?.toString() ?? '',
      accountId: row['account_id']?.toString() ?? defaultAccountId,
      name: row['name']?.toString() ?? '',
      color: (row['color'] as num?)?.toInt() ?? 0xFF2160AB,
      avatarUrl: _normalizeNullable(row['avatar_url']?.toString()),
      createdAt: _millisToDateTime(row['created_at']),
      isKid: (row['is_kid'] as num?)?.toInt() == 1,
      pegiLimit: (row['pegi_limit'] as num?)?.toInt(),
      hasPin: (row['has_pin'] as num?)?.toInt() == 1,
    );
  }

  DateTime? _millisToDateTime(Object? raw) {
    final millis = (raw as num?)?.toInt();
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  String _nextLocalId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(1 << 32);
    return 'local_profile_${micros}_$random';
  }

  String? _normalizeAccountId(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _normalizeNullable(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
