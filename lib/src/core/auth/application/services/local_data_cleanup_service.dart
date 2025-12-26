import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';

/// Service responsable du nettoyage de toutes les données locales lors de la déconnexion.
///
/// Supprime :
/// - Toutes les sources IPTV et leurs données associées
/// - L'historique de lecture
/// - Les playlists
/// - La watchlist
/// - "Continuer à regarder"
/// - Le cache (historique de recherche, etc.)
/// - Les préférences sécurisées
/// - La queue de synchronisation
class LocalDataCleanupService {
  LocalDataCleanupService({required Database db, required GetIt sl})
      : _db = db,
        _sl = sl;

  final Database _db;
  final GetIt _sl;

  /// Supprime toutes les données locales de l'utilisateur.
  ///
  /// Cette méthode est appelée lors de la déconnexion pour nettoyer
  /// complètement l'appareil avant de rediriger vers la page d'authentification.
  Future<void> clearAllLocalData() async {
    if (kDebugMode) {
      debugPrint('[LocalDataCleanupService] Starting local data cleanup...');
    }

    try {
      // 1) Supprimer toutes les sources IPTV et leurs données associées
      await _clearIptvData();

      // 2) Supprimer l'historique de lecture
      await _clearHistory();

      // 3) Supprimer les playlists
      await _clearPlaylists();

      // 4) Supprimer la watchlist
      await _clearWatchlist();

      // 5) Supprimer "continuer à regarder"
      await _clearContinueWatching();

      // 6) Nettoyer le cache (historique de recherche, etc.)
      await _clearCache();

      // 7) Nettoyer les préférences sécurisées
      await _clearSecureStorage();

      // 8) Nettoyer la queue de synchronisation
      await _clearSyncOutbox();

      // 9) Nettoyer le vault des credentials IPTV
      await _clearCredentialsVault();

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Local data cleanup completed');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error during cleanup: $e\n$st');
      }
      // On continue même en cas d'erreur pour ne pas bloquer la déconnexion
    }
  }

  Future<void> _clearIptvData() async {
    if (!_sl.isRegistered<IptvLocalRepository>()) return;

    try {
      final iptvRepo = _sl<IptvLocalRepository>();
      final accounts = await iptvRepo.getAccounts();

      // Supprimer chaque compte (cela supprime aussi les playlists associées)
      for (final account in accounts) {
        await iptvRepo.removeAccount(account.id);
      }

      if (kDebugMode) {
        debugPrint(
          '[LocalDataCleanupService] Cleared ${accounts.length} IPTV account(s)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error clearing IPTV data: $e');
      }
    }
  }

  Future<void> _clearHistory() async {
    try {
      final db = _db;

      // Supprimer tout l'historique
      await db.delete('history');

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared playback history');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error clearing history: $e');
      }
    }
  }

  Future<void> _clearPlaylists() async {
    try {
      final db = _db;

      // Supprimer toutes les playlists et leurs items
      await db.delete('playlist_items');
      await db.delete('playlists');

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared playlists');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error clearing playlists: $e');
      }
    }
  }

  Future<void> _clearWatchlist() async {
    try {
      final db = _db;

      // Supprimer toute la watchlist
      await db.delete('watchlist');

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared watchlist');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error clearing watchlist: $e');
      }
    }
  }

  Future<void> _clearContinueWatching() async {
    try {
      final db = _db;

      // Supprimer tous les "continuer à regarder"
      await db.delete('continue_watching');

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared continue watching');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LocalDataCleanupService] Error clearing continue watching: $e',
        );
      }
    }
  }

  Future<void> _clearCache() async {
    if (!_sl.isRegistered<ContentCacheRepository>()) return;

    try {
      final cacheRepo = _sl<ContentCacheRepository>();

      // Nettoyer les types de cache connus
      await cacheRepo.clearType('search');
      await cacheRepo.clearType('settings');

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error clearing cache: $e');
      }
    }
  }

  Future<void> _clearSecureStorage() async {
    if (!_sl.isRegistered<SecureStorageRepository>()) return;

    try {
      final secureRepo = _sl<SecureStorageRepository>();

      // Nettoyer toutes les clés de préférences connues
      // Note: on ne peut pas tout supprimer car certaines clés sont système
      // On supprime seulement les clés utilisateur
      final userKeys = [
        'selected_profile_id',
        'selected_iptv_source_id',
        'accent_color',
        'preferred_audio_language',
        'preferred_subtitle_language',
        'preferred_locale',
        'theme_mode',
        'iptv_sync_interval',
      ];

      for (final key in userKeys) {
        try {
          await secureRepo.remove(key);
        } catch (_) {
          // Ignorer les erreurs si la clé n'existe pas
        }
      }

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared secure storage');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LocalDataCleanupService] Error clearing secure storage: $e',
        );
      }
    }
  }

  Future<void> _clearSyncOutbox() async {
    try {
      final db = _db;

      // Supprimer toute la queue de synchronisation
      await db.delete('sync_outbox');

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared sync outbox');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Error clearing sync outbox: $e');
      }
    }
  }

  Future<void> _clearCredentialsVault() async {
    if (!_sl.isRegistered<CredentialsVault>()) return;

    try {
      final vault = _sl<CredentialsVault>();

      // Récupérer tous les comptes IPTV pour supprimer leurs credentials
      if (_sl.isRegistered<IptvLocalRepository>()) {
        final iptvRepo = _sl<IptvLocalRepository>();
        final accounts = await iptvRepo.getAccounts();

        for (final account in accounts) {
          try {
            await vault.removePassword(account.id);
          } catch (_) {
            // Ignorer les erreurs si le credential n'existe pas
          }
        }
      }

      if (kDebugMode) {
        debugPrint('[LocalDataCleanupService] Cleared credentials vault');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LocalDataCleanupService] Error clearing credentials vault: $e',
        );
      }
    }
  }
}
