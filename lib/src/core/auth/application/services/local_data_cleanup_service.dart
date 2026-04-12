import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/preferences/suppressed_remote_iptv_sources_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart'
    as content_cache_repo;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';

/// Service responsable du nettoyage des données locales lors de la déconnexion.
///
/// Le nettoyage est volontairement tolérant aux erreurs : une étape qui échoue
/// ne doit pas bloquer la déconnexion.
class LocalDataCleanupService {
  LocalDataCleanupService({required Database db, required GetIt sl})
    : _db = db,
      _sl = sl;

  static const List<String> _secureStorageKeysToRemove = <String>[
    SelectedProfilePreferences.defaultStorageKey,
    SelectedIptvSourcePreferences.defaultStorageKey,
    'selected_profile_id',
    'selected_iptv_source_id',
    'accent_color',
    'prefs.accent_color',
    'preferred_audio_language',
    'preferred_subtitle_language',
    'preferred_locale',
    'theme_mode',
    'iptv_sync_interval',
    SuppressedRemoteIptvSourcesPreferences.defaultStorageKey,
  ];

  static const List<String> _sensitiveSessionKeysToRemove = <String>[
    SelectedProfilePreferences.defaultStorageKey,
    SelectedIptvSourcePreferences.defaultStorageKey,
    'selected_profile_id',
    'selected_iptv_source_id',
  ];

  static const List<String> _cacheTypesToClear = <String>['search', 'settings'];

  final Database _db;
  final GetIt _sl;

  /// Clears only auth/session-derived local state that can otherwise keep the
  /// app in an unsafe or ambiguous recovery path after an invalid session.
  ///
  /// This intentionally preserves local-first assets such as profiles, IPTV
  /// sources, playlists, and caches that remain valid offline.
  Future<void> clearSensitiveSessionState() async {
    _log('Starting sensitive session cleanup...');
    await _clearSecureStorageKeys(_sensitiveSessionKeysToRemove);
    await _clearSyncOutbox();
    _log('Sensitive session cleanup completed');
  }

  /// Supprime toutes les données locales de l'utilisateur.
  Future<void> clearAllLocalData() async {
    _log('Starting local data cleanup...');

    final cleanupTargets = await _loadIptvCleanupTargets();

    // Important : supprimer les credentials avant les comptes IPTV,
    // sinon les identifiants peuvent ne plus être accessibles.
    await _clearCredentialsVault(cleanupTargets.accountIds);
    await _clearIptvData(cleanupTargets);

    await _clearHistory();
    await _clearPlaylists();
    await _clearWatchlist();
    await _clearContinueWatching();
    await _clearCache();
    await _clearSecureStorage();
    await _clearSyncOutbox();

    _log('Local data cleanup completed');
  }

  Future<_IptvCleanupTargets> _loadIptvCleanupTargets() async {
    final iptvRepository = _getOptional<IptvLocalRepository>();
    if (iptvRepository == null) {
      return const _IptvCleanupTargets.empty();
    }

    try {
      final xtreamAccounts = await iptvRepository.getAccounts(
        includeAllOwners: true,
      );
      final stalkerAccounts = await iptvRepository.getStalkerAccounts(
        includeAllOwners: true,
      );
      return _IptvCleanupTargets(
        xtreamAccountIds: xtreamAccounts.map((account) => account.id).toList(),
        stalkerAccountIds: stalkerAccounts
            .map((account) => account.id)
            .toList(),
      );
    } catch (error, stackTrace) {
      _log('Error loading IPTV accounts for cleanup: $error\n$stackTrace');
      return const _IptvCleanupTargets.empty();
    }
  }

  Future<void> _clearIptvData(_IptvCleanupTargets targets) async {
    final iptvRepository = _getOptional<IptvLocalRepository>();
    if (iptvRepository == null || targets.isEmpty) {
      return;
    }

    await _runSafely(
      errorContext: 'clearing IPTV data',
      action: () async {
        for (final accountId in targets.xtreamAccountIds) {
          await iptvRepository.removeAccount(accountId, includeAllOwners: true);
        }
        for (final accountId in targets.stalkerAccountIds) {
          await iptvRepository.removeStalkerAccount(
            accountId,
            includeAllOwners: true,
          );
        }

        _log(
          'Cleared ${targets.accountIds.length} IPTV account(s) across all owners',
        );
      },
    );
  }

  Future<void> _clearHistory() async {
    await _deleteTables(
      tableNames: const <String>['history'],
      successMessage: 'Cleared playback history',
      errorContext: 'clearing playback history',
    );
  }

  Future<void> _clearPlaylists() async {
    await _deleteTables(
      tableNames: const <String>['playlist_items', 'playlists'],
      successMessage: 'Cleared playlists',
      errorContext: 'clearing playlists',
    );
  }

  Future<void> _clearWatchlist() async {
    await _deleteTables(
      tableNames: const <String>['watchlist'],
      successMessage: 'Cleared watchlist',
      errorContext: 'clearing watchlist',
    );
  }

  Future<void> _clearContinueWatching() async {
    await _deleteTables(
      tableNames: const <String>['continue_watching'],
      successMessage: 'Cleared continue watching',
      errorContext: 'clearing continue watching',
    );
  }

  Future<void> _clearCache() async {
    final cacheRepository =
        _getOptional<content_cache_repo.ContentCacheRepository>();
    if (cacheRepository == null) {
      return;
    }

    await _runSafely(
      errorContext: 'clearing cache',
      action: () async {
        for (final cacheType in _cacheTypesToClear) {
          await cacheRepository.clearType(cacheType);
        }

        _log('Cleared cache');
      },
    );
  }

  Future<void> _clearSecureStorage() async {
    await _clearSecureStorageKeys(_secureStorageKeysToRemove);
  }

  Future<void> _clearSecureStorageKeys(List<String> keys) async {
    final secureStorageRepository = _getOptional<SecureStorageRepository>();
    if (secureStorageRepository == null) {
      return;
    }

    await _runSafely(
      errorContext: 'clearing secure storage',
      action: () async {
        for (final key in keys) {
          try {
            await secureStorageRepository.remove(key);
          } catch (error) {
            _log('Skipped secure storage key "$key": $error');
          }
        }

        _log('Cleared secure storage');
      },
    );
  }

  Future<void> _clearSyncOutbox() async {
    await _deleteTables(
      tableNames: const <String>['sync_outbox'],
      successMessage: 'Cleared sync outbox',
      errorContext: 'clearing sync outbox',
    );
  }

  Future<void> _clearCredentialsVault(List<String> accountIds) async {
    final credentialsVault = _getOptional<CredentialsVault>();
    if (credentialsVault == null || accountIds.isEmpty) {
      return;
    }

    await _runSafely(
      errorContext: 'clearing credentials vault',
      action: () async {
        for (final accountId in accountIds) {
          try {
            await credentialsVault.removePassword(accountId);
          } catch (error) {
            _log('Skipped credential removal for account "$accountId": $error');
          }
        }

        _log('Cleared credentials vault');
      },
    );
  }

  Future<void> _deleteTables({
    required List<String> tableNames,
    required String successMessage,
    required String errorContext,
  }) async {
    await _runSafely(
      errorContext: errorContext,
      action: () async {
        for (final tableName in tableNames) {
          await _db.delete(tableName);
        }

        _log(successMessage);
      },
    );
  }

  Future<void> _runSafely({
    required String errorContext,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _log('Error $errorContext: $error\n$stackTrace');
    }
  }

  T? _getOptional<T extends Object>() {
    if (!_sl.isRegistered<T>()) {
      return null;
    }

    return _sl<T>();
  }

  void _log(String message) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('[LocalDataCleanupService] $message');
  }
}

final class _IptvCleanupTargets {
  const _IptvCleanupTargets({
    required this.xtreamAccountIds,
    required this.stalkerAccountIds,
  });

  const _IptvCleanupTargets.empty()
    : xtreamAccountIds = const <String>[],
      stalkerAccountIds = const <String>[];

  final List<String> xtreamAccountIds;
  final List<String> stalkerAccountIds;

  List<String> get accountIds => <String>{
    ...xtreamAccountIds,
    ...stalkerAccountIds,
  }.toList(growable: false);

  bool get isEmpty => xtreamAccountIds.isEmpty && stalkerAccountIds.isEmpty;
}
