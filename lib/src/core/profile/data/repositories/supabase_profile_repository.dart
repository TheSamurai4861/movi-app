import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/profile/data/datasources/supabase_profile_datasource.dart';
import 'package:movi/src/core/profile/data/dtos/profile_dto.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(
    this._client, {
    required SupabaseProfileDatasource datasource,
    bool? diagnosticsEnabled,
  })  : _ds = datasource,
        _diagnosticsEnabled = diagnosticsEnabled ?? kDebugMode;

  final SupabaseClient _client;
  final SupabaseProfileDatasource _ds;
  final bool _diagnosticsEnabled;

  void _diag(String message) {
    if (!_diagnosticsEnabled) return;
    debugPrint('[SupabaseProfileRepository] $message');
  }

  String _resolveAccountId(String? accountId) {
    final explicit = accountId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      _diag('resolveAccountId: using explicit accountId=$explicit');
      return explicit;
    }

    final fromClient = _client.auth.currentUser?.id;
    if (fromClient != null && fromClient.trim().isNotEmpty) {
      final resolved = fromClient.trim();
      _diag('resolveAccountId: using client.auth.currentUser.id=$resolved');
      return resolved;
    }

    _diag('resolveAccountId FAILED: auth.currentUser is null/empty.');
    throw StateError('User not authenticated (Supabase auth.currentUser is null).');
  }

  @override
  Future<List<Profile>> getProfiles({String? accountId, bool? diagnostics}) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    void log(String msg) {
      if (!diagOn) return;
      debugPrint('[SupabaseProfileRepository] $msg');
    }

    log('getProfiles: start filter account_id="$resolvedAccountId"');

    return _retryWithBackoff<List<Profile>>(
      operation: () async {
        final rows = await _ds.selectProfilesByAccountId(resolvedAccountId);

        final entities = rows
            .map((row) => ProfileDto.fromJson(row).toEntity())
            .toList(growable: true)
          ..sort((a, b) => _compareNullableDateTime(a.createdAt, b.createdAt));

        log('getProfiles: OK -> ${entities.length} row(s)');
        return entities;
      },
      operationName: 'getProfiles',
      maxRetries: 3,
      log: log,
    );
  }

  /// Retry automatique avec backoff exponentiel pour les erreurs de connexion réseau.
  Future<T> _retryWithBackoff<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    void Function(String)? log,
  }) async {
    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        // Vérifier si c'est une erreur de connexion réseau retryable
        final isRetryable = _isRetryableNetworkError(error);
        
        if (!isRetryable || attempt >= maxRetries) {
          log?.call('$operationName: ERROR type=${error.runtimeType} message=$error');
          throw mapSupabaseError(error, stackTrace: stackTrace);
        }

        // Backoff exponentiel : 300ms, 600ms, 1200ms
        final backoffDelay = Duration(milliseconds: 300 * (1 << attempt));
        log?.call(
          '$operationName: retryable network error (attempt ${attempt + 1}/${maxRetries + 1}), retrying after ${backoffDelay.inMilliseconds}ms',
        );
        
        await Future.delayed(backoffDelay);
        attempt++;
      }
    }
    // Ne devrait jamais arriver, mais pour satisfaire l'analyse statique
    throw StateError('Retry loop ended unexpectedly');
  }

  /// Vérifie si l'erreur est une erreur de connexion réseau retryable.
  bool _isRetryableNetworkError(Object error) {
    // Vérifier SocketException directement
    if (error is SocketException) {
      return true;
    }

    // Vérifier le type d'erreur par le nom de classe (pour _ClientSocketException, ClientException, etc.)
    final errorType = error.runtimeType.toString();
    if (errorType.contains('SocketException') ||
        errorType.contains('ClientException') ||
        errorType.contains('_ClientSocketException')) {
      // Vérifier aussi le message pour confirmer
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('socket') ||
          errorString.contains('timeout') ||
          errorString.contains('connection') ||
          errorString.contains('errno = 121') || // Timeout de sémaphore
          errorString.contains('errno = 10057')) { // Socket non connecté
        return true;
      }
    }

    return false;
  }

  @override
  Future<Profile> createProfile({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  }) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty.');
    }

    final diagOn = diagnostics ?? _diagnosticsEnabled;
    void log(String msg) {
      if (!diagOn) return;
      debugPrint('[SupabaseProfileRepository] $msg');
    }

    final fullPayload = <String, dynamic>{
      SupabaseProfileDatasource.colAccountId: resolvedAccountId,
      'name': trimmedName,
      'color': color,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final minimalPayload = <String, dynamic>{
      SupabaseProfileDatasource.colAccountId: resolvedAccountId,
      'name': trimmedName,
    };

    log('createProfile: start accountId=$resolvedAccountId name="$trimmedName"');

    try {
      final row = await _ds.insertProfile(fullPayload);
      return ProfileDto.fromJson(row).toEntity();
    } catch (error) {
      log('createProfile: full insert failed -> retry minimal. type=${error.runtimeType} $error');

      try {
        final row = await _ds.insertProfile(minimalPayload);
        return ProfileDto.fromJson(row).toEntity();
      } catch (error2, stackTrace2) {
        log('createProfile: minimal insert failed. type=${error2.runtimeType} $error2');
        throw mapSupabaseError(error2, stackTrace: stackTrace2);
      }
    }
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
    final diagOn = diagnostics ?? _diagnosticsEnabled;
    void log(String msg) {
      if (!diagOn) return;
      debugPrint('[SupabaseProfileRepository] $msg');
    }

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name.trim();
      if (color != null) updates['color'] = color;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (isKid != null) updates['is_kid'] = isKid;
      if (!identical(pegiLimit, ProfileRepository.noChange)) {
        updates['pegi_limit'] = pegiLimit as int?;
      }

      if (updates.isEmpty) {
        log('updateProfile: no updates -> refetch profileId=$profileId');
        final row = await _ds.selectProfileById(profileId);
        return ProfileDto.fromJson(row).toEntity();
      }

      final row = await _ds.updateProfile(profileId: profileId, updates: updates);
      return ProfileDto.fromJson(row).toEntity();
    } catch (error, stackTrace) {
      log('updateProfile: ERROR type=${error.runtimeType} message=$error');
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> deleteProfile(String profileId, {bool? diagnostics}) async {
    final diagOn = diagnostics ?? _diagnosticsEnabled;
    void log(String msg) {
      if (!diagOn) return;
      debugPrint('[SupabaseProfileRepository] $msg');
    }

    try {
      log('deleteProfile: start profileId=$profileId');
      await _ds.deleteProfile(profileId);
      log('deleteProfile: OK profileId=$profileId');
    } catch (error, stackTrace) {
      log('deleteProfile: ERROR type=${error.runtimeType} message=$error');
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }

  @override
  Future<Profile> getOrCreateDefaultProfile({String? accountId, bool? diagnostics}) async {
    final resolvedAccountId = _resolveAccountId(accountId);
    final diagOn = diagnostics ?? _diagnosticsEnabled;

    final profiles = await getProfiles(accountId: resolvedAccountId, diagnostics: diagOn);
    if (profiles.isNotEmpty) return profiles.first;

    final user = _client.auth.currentUser;
    final fallbackFromEmail = user?.email?.split('@').first.trim();
    final defaultName = (fallbackFromEmail != null && fallbackFromEmail.isNotEmpty)
        ? fallbackFromEmail
        : resolvedAccountId.substring(0, 8);

    return createProfile(
      accountId: resolvedAccountId,
      name: defaultName,
      color: 0xFF2160AB,
      diagnostics: diagOn,
    );
  }

  static int _compareNullableDateTime(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}






