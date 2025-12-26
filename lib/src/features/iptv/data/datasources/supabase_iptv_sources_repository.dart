// lib/src/core/iptv/data/repositories/supabase_iptv_sources_repository.dart

import 'dart:developer' as dev;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool? _parseBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
  }
  return null;
}

/// Clarifie le "point de vérité" pour les sources IPTV.
///
/// - [minimalRemoteOnly]:
///   Supabase stocke uniquement des métadonnées non sensibles (name/is_active/last_sync/expires_at).
///   Les credentials (server_url/username/password) sont purement locaux (vault/local storage).
///
/// - [remoteWithServerMeta]:
///   Supabase stocke aussi `server_url` + `username` (métadonnées),
///   mais JAMAIS le mot de passe en clair (le password reste local/chiffré).
///
/// IMPORTANT:
/// - Peu importe le mode, l’UI doit être alignée sur le modèle lu/écrit.
/// - Si tu écris `server_url`/`username`/`local_id`, tu dois les relire et les exposer.
enum IptvSourceTruthMode { minimalRemoteOnly, remoteWithServerMeta }

/// DTO Supabase (data-layer). Le nom contient "Entity" dans ton code existant:
/// on le garde pour ne pas casser les imports, mais conceptuellement c’est un DTO.
class SupabaseIptvSourceEntity {
  const SupabaseIptvSourceEntity({
    required this.id,
    required this.accountId,
    required this.name,
    this.localId,
    this.isActive,
    this.lastSyncAt,
    this.expiresAt,
    this.serverUrl,
    this.username,
    this.encryptedCredentials,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String accountId;
  final String name;

  /// Identifiant local (si présent en DB) — utilisé par upsert onConflict='account_id,local_id'
  final String? localId;

  /// Métadonnées "remote" (recommandées, non sensibles)
  final bool? isActive;
  final DateTime? lastSyncAt;
  final DateTime? expiresAt;

  /// Métadonnées serveur (optionnelles selon [IptvSourceTruthMode])
  final String? serverUrl;
  final String? username;

  /// Optionnel:
  /// - soit tu ne stockes rien côté Supabase et tu redemandes le password sur nouvel appareil
  /// - soit tu stockes un blob chiffré (attention UX/sécurité/rotation de clés)
  final String? encryptedCredentials;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SupabaseIptvSourceEntity.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawAccountId = json['account_id'] ?? json['accountId'];

    if (rawId == null) {
      throw const FormatException('Missing iptv_sources.id');
    }
    if (rawAccountId == null) {
      throw const FormatException('Missing iptv_sources.account_id');
    }

    return SupabaseIptvSourceEntity(
      id: rawId.toString(),
      accountId: rawAccountId.toString(),
      name: (json['name'] as String?)?.trim() ?? '',
      localId: (json['local_id'] as String?)?.trim(),
      isActive: _parseBool(json['is_active']),
      lastSyncAt: _parseDateTime(json['last_sync_at'] ?? json['last_sync']),
      expiresAt: _parseDateTime(json['expires_at']),
      serverUrl: (json['server_url'] as String?)?.trim(),
      username: (json['username'] as String?)?.trim(),
      encryptedCredentials: json['encrypted_credentials'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'account_id': accountId,
        'name': name,
        if (localId != null) 'local_id': localId,
        'is_active': isActive,
        'last_sync_at': lastSyncAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'server_url': serverUrl,
        'username': username,
        'encrypted_credentials': encryptedCredentials,
      };
}

class SupabaseIptvSourcesRepository {
  SupabaseIptvSourcesRepository(
    this._client, {
    IptvSourceTruthMode? truthMode,
    bool? diagnosticsEnabled,
  })  : _truthMode = truthMode ?? IptvSourceTruthMode.remoteWithServerMeta,
        _diagnosticsEnabled =
            diagnosticsEnabled ?? !const bool.fromEnvironment('dart.vm.product');

  final SupabaseClient _client;
  final IptvSourceTruthMode _truthMode;
  final bool _diagnosticsEnabled;

  static const String _table = 'iptv_sources';

  void _diag(String message) {
    if (!_diagnosticsEnabled) return;
    dev.log(message, name: 'SupabaseIptvSourcesRepository');
  }

  String _resolveAccountId(String? accountId) {
    final explicit = accountId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromClient = _client.auth.currentUser?.id;
    if (fromClient != null && fromClient.trim().isNotEmpty) return fromClient;

    _diag(
      'accountId unresolved. auth.currentUser is null/empty. '
      'Possible causes: Supabase not initialized, client mismatch in DI, or session not restored yet.',
    );

    throw StateError('User not authenticated (Supabase auth.currentUser is null).');
  }

  /// Colonnes lues depuis Supabase.
  ///
  /// NOTE: si certaines colonnes n’existent pas en DB, Supabase renverra une erreur.
  /// Adapte cette liste à TON schéma exact côté Supabase.
  String _selectColumns() {
    return <String>[
      'id',
      'account_id',
      'local_id', // IMPORTANT: aligné avec upsert onConflict='account_id,local_id'
      'name',
      'is_active',
      'last_sync_at',
      'expires_at',
      'server_url',
      'username',
      'encrypted_credentials',
      'created_at',
      'updated_at',
    ].join(',');
  }

  Future<List<SupabaseIptvSourceEntity>> getSources({
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    void log(String msg) {
      if (!diagOn) return;
      dev.log(msg, name: 'SupabaseIptvSourcesRepository');
    }

    log('getSources: start uid=$resolvedAccountId mode=$_truthMode');

    try {
      final rows = await _client
          .from(_table)
          .select(_selectColumns())
          .eq('account_id', resolvedAccountId);

      final list = (rows as List)
          .map((e) => SupabaseIptvSourceEntity.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);

      log('getSources: OK -> ${list.length} row(s)');
      return list;
    } catch (error, stackTrace) {
      log(
        'getSources: ERROR type=${error.runtimeType} message=$error. '
        'Likely causes: RLS denies SELECT, wrong env, schema mismatch, client mismatch, network failure.',
      );
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  Future<SupabaseIptvSourceEntity> createSource({
    required String name,
    bool? isActive,
    DateTime? lastSyncAt,
    DateTime? expiresAt,
    String? serverUrl,
    String? username,
    String? encryptedCredentials,
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    void log(String msg) {
      if (!diagOn) return;
      dev.log(msg, name: 'SupabaseIptvSourcesRepository');
    }

    final payload = <String, dynamic>{
      'account_id': resolvedAccountId,
      'name': name,
      if (isActive != null) 'is_active': isActive,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      if (encryptedCredentials != null) 'encrypted_credentials': encryptedCredentials,
    };

    if (_truthMode == IptvSourceTruthMode.remoteWithServerMeta) {
      if (serverUrl != null) payload['server_url'] = serverUrl;
      if (username != null) payload['username'] = username;
    }

    log('createSource: start uid=$resolvedAccountId mode=$_truthMode');

    try {
      final row = await _client.from(_table).insert(payload).select(_selectColumns()).single();
      log('createSource: OK');
      return SupabaseIptvSourceEntity.fromJson(row);
    } catch (error, stackTrace) {
      log('createSource: ERROR type=${error.runtimeType} message=$error');
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  Future<SupabaseIptvSourceEntity> updateSource({
    required String id,
    String? name,
    bool? isActive,
    DateTime? lastSyncAt,
    DateTime? expiresAt,
    String? serverUrl,
    String? username,
    String? encryptedCredentials,
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    void log(String msg) {
      if (!diagOn) return;
      dev.log(msg, name: 'SupabaseIptvSourcesRepository');
    }

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (isActive != null) updates['is_active'] = isActive;
      if (lastSyncAt != null) updates['last_sync_at'] = lastSyncAt.toIso8601String();
      if (expiresAt != null) updates['expires_at'] = expiresAt.toIso8601String();
      if (encryptedCredentials != null) updates['encrypted_credentials'] = encryptedCredentials;

      if (_truthMode == IptvSourceTruthMode.remoteWithServerMeta) {
        if (serverUrl != null) updates['server_url'] = serverUrl;
        if (username != null) updates['username'] = username;
      }

      log('updateSource: start id=$id uid=$resolvedAccountId fields=${updates.keys.toList()}');

      final row = await _client
          .from(_table)
          .update(updates)
          .eq('id', id)
          .eq('account_id', resolvedAccountId)
          .select(_selectColumns())
          .single();

      log('updateSource: OK id=$id');
      return SupabaseIptvSourceEntity.fromJson(row);
    } catch (error, stackTrace) {
      log('updateSource: ERROR type=${error.runtimeType} message=$error');
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  /// Upsert (insert ou update) basé sur la contrainte UNIQUE(account_id, local_id).
  Future<SupabaseIptvSourceEntity> upsertSource({
    required String localId,
    required String name,
    bool? isActive,
    DateTime? lastSyncAt,
    DateTime? expiresAt,
    String? serverUrl,
    String? username,
    String? encryptedCredentials,
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    void log(String msg) {
      if (!diagOn) return;
      dev.log(msg, name: 'SupabaseIptvSourcesRepository');
    }

    final payload = <String, dynamic>{
      'account_id': resolvedAccountId,
      'local_id': localId,
      'name': name,
      if (isActive != null) 'is_active': isActive,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      if (encryptedCredentials != null) 'encrypted_credentials': encryptedCredentials,
    };

    if (_truthMode == IptvSourceTruthMode.remoteWithServerMeta) {
      if (serverUrl != null) payload['server_url'] = serverUrl;
      if (username != null) payload['username'] = username;
    }

    log('upsertSource: start uid=$resolvedAccountId localId=$localId mode=$_truthMode');

    try {
      final row = await _client
          .from(_table)
          .upsert(payload, onConflict: 'account_id,local_id')
          .select(_selectColumns())
          .single();

      log('upsertSource: OK');
      return SupabaseIptvSourceEntity.fromJson(row);
    } catch (error, stackTrace) {
      log('upsertSource: ERROR type=${error.runtimeType} message=$error');
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  Future<void> deleteSource({
    required String id,
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    void log(String msg) {
      if (!diagOn) return;
      dev.log(msg, name: 'SupabaseIptvSourcesRepository');
    }

    try {
      log('deleteSource: start id=$id uid=$resolvedAccountId');
      await _client.from(_table).delete().eq('id', id).eq('account_id', resolvedAccountId);
      log('deleteSource: OK id=$id');
    } catch (error, stackTrace) {
      log('deleteSource: ERROR type=${error.runtimeType} message=$error');
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }
}
