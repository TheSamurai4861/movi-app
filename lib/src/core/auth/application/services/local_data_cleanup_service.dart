import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

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
    'selected_profile_id',
    'selected_iptv_source_id',
    'accent_color',
    'prefs.accent_color',
    'preferred_audio_language',
    'preferred_subtitle_language',
    'preferred_locale',
    'theme_mode',
    'iptv_sync_interval',
  ];

  static const List<String> _sensitiveSessionKeysToRemove = <String>[
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

    final iptvAccounts = await _loadIptvAccountsForCleanup();

    // Important : supprimer les credentials avant les comptes IPTV,
    // sinon les identifiants peuvent ne plus être accessibles.
    await _clearCredentialsVault(iptvAccounts);
    await _clearIptvData(iptvAccounts);

    await _clearHistory();
    await _clearPlaylists();
    await _clearWatchlist();
    await _clearContinueWatching();
    await _clearCache();
    await _clearSecureStorage();
    await _clearSyncOutbox();

    _log('Local data cleanup completed');
  }

  Future<List<dynamic>> _loadIptvAccountsForCleanup() async {
    final iptvRepository = _getOptional<IptvLocalRepository>();
    if (iptvRepository == null) {
      return const <dynamic>[];
    }

    try {
      return await iptvRepository.getAccounts();
    } catch (error, stackTrace) {
      _log('Error loading IPTV accounts for cleanup: $error\n$stackTrace');
      return const <dynamic>[];
    }
  }

  Future<void> _clearIptvData(List<dynamic> accounts) async {
    final iptvRepository = _getOptional<IptvLocalRepository>();
    if (iptvRepository == null || accounts.isEmpty) {
      return;
    }

    await _runSafely(
      errorContext: 'clearing IPTV data',
      action: () async {
        for (final account in accounts) {
          await iptvRepository.removeAccount(account.id);
        }

        _log('Cleared ${accounts.length} IPTV account(s)');
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
    final cacheRepository = _getOptional<content_cache_repo.ContentCacheRepository>();
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

  Future<void> _clearCredentialsVault(List<dynamic> accounts) async {
    final credentialsVault = _getOptional<CredentialsVault>();
    if (credentialsVault == null || accounts.isEmpty) {
      return;
    }

    await _runSafely(
      errorContext: 'clearing credentials vault',
      action: () async {
        for (final account in accounts) {
          try {
            await credentialsVault.removePassword(account.id);
          } catch (error) {
            _log(
              'Skipped credential removal for account "${account.id}": $error',
            );
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
