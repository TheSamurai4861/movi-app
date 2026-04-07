import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/library/application/services/cloud_selected_profile_id_sanitizer.dart';
import 'package:movi/src/features/library/application/services/library_cloud_sync_service.dart';

/// Service de synchronisation complète qui gère :
/// - Bibliothèque (playlists, favoris, historique) via LibraryCloudSyncService
/// - Profils (pull depuis Supabase)
/// - Sources IPTV (push local -> Supabase)
/// - Préférences utilisateur (accent color, player prefs, locale, etc.)
class ComprehensiveCloudSyncService {
  ComprehensiveCloudSyncService({
    required GetIt sl,
    required LibraryCloudSyncService librarySync,
    CloudSelectedProfileIdSanitizer? selectedProfileIdSanitizer,
  }) : _sl = sl,
       _librarySync = librarySync,
       _selectedProfileIdSanitizer =
           selectedProfileIdSanitizer ??
           const CloudSelectedProfileIdSanitizer();

  final GetIt _sl;
  final LibraryCloudSyncService _librarySync;
  final CloudSelectedProfileIdSanitizer _selectedProfileIdSanitizer;

  static const String _prefsTable = 'user_preferences';

  static Map<String, dynamic>? _coercePreferencesMap(Object? raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(
        raw.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        return _coercePreferencesMap(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Synchronise tous les éléments : bibliothèque, profils, sources IPTV, préférences.
  Future<void> syncAll({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    // 1. Synchroniser la bibliothèque (playlists, favoris, historique)
    await _librarySync.syncAll(
      client: client,
      profileId: profileId,
      shouldCancel: shouldCancel,
    );

    if (shouldCancel?.call() == true) return;

    // 2. Synchroniser les profils (pull depuis Supabase)
    await _syncProfiles(client: client, shouldCancel: shouldCancel);

    if (shouldCancel?.call() == true) return;

    // 3. Synchroniser les sources IPTV (push local -> Supabase)
    await _syncIptvSourcesPush(client: client, shouldCancel: shouldCancel);

    if (shouldCancel?.call() == true) return;

    // 4. Synchroniser les préférences utilisateur
    await _syncUserPreferences(client: client, shouldCancel: shouldCancel);
  }

  /// Push uniquement les préférences utilisateur (ex. après choix de source IPTV).
  Future<void> pushUserPreferences({required SupabaseClient client}) async {
    await _syncUserPreferences(client: client, shouldCancel: () => false);
  }

  /// Synchronise les profils depuis Supabase (pull).
  /// Les profils sont déjà gérés par le ProfileRepository Supabase,
  /// on s'assure juste qu'ils sont à jour.
  Future<void> _syncProfiles({
    required SupabaseClient client,
    bool Function()? shouldCancel,
  }) async {
    // Le refresh des profils est géré par le ProfilesController
    // On ne fait rien ici car les profils sont déjà synchronisés
    // via le repository Supabase lors des opérations CRUD.
  }

  /// Synchronise les sources IPTV locales vers Supabase (push).
  /// Récupère toutes les sources locales et les pousse vers Supabase.
  Future<void> _syncIptvSourcesPush({
    required SupabaseClient client,
    bool Function()? shouldCancel,
  }) async {
    final uid = client.auth.currentSession?.user.id.trim();
    if (uid == null || uid.isEmpty) return;

    if (!_sl.isRegistered<SupabaseIptvSourcesRepository>()) return;
    if (!_sl.isRegistered<IptvCredentialsEdgeService>()) return;
    if (!_sl.isRegistered<IptvLocalRepository>()) return;
    if (!_sl.isRegistered<CredentialsVault>()) return;

    final sourcesRepo = _sl<SupabaseIptvSourcesRepository>();
    final edge = _sl<IptvCredentialsEdgeService>();
    final localRepo = _sl<IptvLocalRepository>();
    final vault = _sl<CredentialsVault>();

    try {
      // Récupérer toutes les sources locales
      final localAccounts = await localRepo.getAccounts();
      if (localAccounts.isEmpty) return;

      for (final account in localAccounts) {
        if (shouldCancel?.call() == true) return;

        try {
          // Récupérer le mot de passe depuis le vault
          final password = await vault.readPassword(account.id);
          if (password == null || password.isEmpty) {
            // Pas de mot de passe stocké, on ne peut pas synchroniser
            continue;
          }

          // Construire le localId (identique à celui utilisé lors de la création)
          final localId = account.id;

          // Chiffrer les credentials via l'Edge Function
          String? encryptedCredentials;
          try {
            encryptedCredentials = await edge.encrypt(
              username: account.username,
              password: password,
            );
          } catch (e) {
            // Si l'Edge Function n'est pas disponible, on continue sans credentials
            // La source sera synchronisée sans mot de passe (métadonnées uniquement)
            assert(() {
              debugPrint(
                '[ComprehensiveCloudSyncService] Edge function encrypt failed: $e',
              );
              return true;
            }());
          }

          // Upsert dans Supabase
          // Utiliser toRawUrl() pour obtenir l'URL brute au lieu de toString()
          await sourcesRepo
              .upsertSource(
                localId: localId,
                accountId: uid,
                name: account.alias.trim().isNotEmpty
                    ? account.alias.trim()
                    : 'Xtream',
                expiresAt: account.expirationDate,
                serverUrl: account.endpoint.toRawUrl(),
                username: account.username,
                encryptedCredentials: encryptedCredentials,
                isActive: true,
                lastSyncAt: DateTime.now().toUtc(),
              )
              .timeout(const Duration(seconds: 5));
        } catch (e, st) {
          assert(() {
            debugPrint(
              '[ComprehensiveCloudSyncService] Failed to sync IPTV source ${account.id}: $e\n$st',
            );
            return true;
          }());
          // Continuer avec les autres sources même en cas d'erreur
        }
      }
    } catch (e, st) {
      assert(() {
        debugPrint(
          '[ComprehensiveCloudSyncService] _syncIptvSourcesPush failed: $e\n$st',
        );
        return true;
      }());
      // Ignorer les erreurs pour ne pas bloquer la sync
    }
  }

  /// Synchronise les préférences utilisateur vers Supabase (push).
  /// Récupère toutes les préférences locales et les pousse vers Supabase.
  Future<void> _syncUserPreferences({
    required SupabaseClient client,
    bool Function()? shouldCancel,
  }) async {
    final uid = client.auth.currentSession?.user.id.trim();
    if (uid == null || uid.isEmpty) return;

    try {
      Map<String, dynamic> existingPrefs = const {};
      try {
        final row = await client
            .from(_prefsTable)
            .select('preferences')
            .eq('account_id', uid)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));
        final parsed = _coercePreferencesMap(row?['preferences']);
        if (parsed != null) {
          existingPrefs = parsed;
        }
      } catch (_) {
        // Ignorer : on repart d'une map vide si la ligne n'existe pas ou erreur réseau.
      }

      final prefs = <String, dynamic>{};

      // Accent color
      if (_sl.isRegistered<AccentColorPreferences>()) {
        final accentPrefs = _sl<AccentColorPreferences>();
        final color = accentPrefs.accentColor;
        prefs['accent_color'] = color
            .toARGB32()
            .toRadixString(16)
            .padLeft(8, '0');
      }

      // Player preferences
      if (_sl.isRegistered<PlayerPreferences>()) {
        final playerPrefs = _sl<PlayerPreferences>();
        prefs['preferred_audio_language'] = playerPrefs.preferredAudioLanguage;
        prefs['preferred_subtitle_language'] =
            playerPrefs.preferredSubtitleLanguage;
      }

      // Locale preferences
      if (_sl.isRegistered<LocalePreferences>()) {
        final localePrefs = _sl<LocalePreferences>();
        prefs['preferred_locale'] = localePrefs.languageCode;
        prefs['theme_mode'] = _stringifyThemeMode(localePrefs.themeMode);
      }

      // Selected profile
      if (_sl.isRegistered<SelectedProfilePreferences>()) {
        final selectedProfilePrefs = _sl<SelectedProfilePreferences>();
        final selectedProfileId = _selectedProfileIdSanitizer.sanitize(
          selectedProfilePrefs.selectedProfileId,
        );
        if (selectedProfileId != null) {
          prefs['selected_profile_id'] = selectedProfileId;
        }
      }

      // Selected IPTV source (ne pas envoyer null : évite d'effacer la valeur distante
      // lors d'un merge ; si absent du patch, on garde la clé déjà en base).
      if (_sl.isRegistered<SelectedIptvSourcePreferences>()) {
        final selectedIptvPrefs = _sl<SelectedIptvSourcePreferences>();
        final iptvId = selectedIptvPrefs.selectedSourceId?.trim();
        if (iptvId != null && iptvId.isNotEmpty) {
          prefs['selected_iptv_source_id'] = iptvId;
        }
      }

      // IPTV sync interval
      if (_sl.isRegistered<IptvSyncPreferences>()) {
        final iptvSyncPrefs = _sl<IptvSyncPreferences>();
        final intervalMinutes = iptvSyncPrefs.syncInterval.inMinutes;
        // Ne pas synchroniser si désactivé (intervalle très long)
        if (intervalMinutes < 365 * 24 * 60) {
          prefs['iptv_sync_interval_minutes'] = intervalMinutes;
        }
      }

      final merged = Map<String, dynamic>.from(existingPrefs);
      merged.addAll(prefs);

      if (merged.isEmpty) return;

      // Upsert dans Supabase (une seule ligne par utilisateur)
      await client
          .from(_prefsTable)
          .upsert({
            'account_id': uid,
            'preferences': merged,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'account_id')
          .timeout(const Duration(seconds: 5));
    } catch (e, st) {
      assert(() {
        debugPrint(
          '[ComprehensiveCloudSyncService] _syncUserPreferences failed: $e\n$st',
        );
        return true;
      }());
      // Ignorer les erreurs pour ne pas bloquer la sync
    }
  }

  /// Pull les préférences utilisateur depuis Supabase et les applique localement.
  ///
  /// Si [knownIptvAccountIds] est fourni (IDs de comptes IPTV locaux actuels), on
  /// peut restaurer ou réparer `selected_iptv_source_id` lorsque le stockage local
  /// est vide ou pointe vers un id obsolète (réimport, autre appareil, etc.).
  Future<void> pullUserPreferences({
    required SupabaseClient client,
    bool Function()? shouldCancel,
    Set<String>? knownIptvAccountIds,
    bool preferLocalAccent = false,
    String context = 'default',
  }) async {
    final uid = client.auth.currentSession?.user.id.trim();
    if (uid == null || uid.isEmpty) return;

    try {
      final response = await client
          .from(_prefsTable)
          .select()
          .eq('account_id', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response == null) return;

      final prefs = _coercePreferencesMap(response['preferences']);
      if (prefs == null || prefs.isEmpty) return;

      // Accent color
      if (_sl.isRegistered<AccentColorPreferences>()) {
        final accentColorStr = prefs['accent_color']?.toString();
        if (accentColorStr != null && accentColorStr.isNotEmpty) {
          try {
            final accentPrefs = _sl<AccentColorPreferences>();
            if (preferLocalAccent) {
              assert(() {
                debugPrint(
                  '[ComprehensiveCloudSyncService] pullUserPreferences '
                  'context=$context local_wins=true -> cloud accent ignored',
                );
                return true;
              }());
            } else {
              final colorValue = int.parse(accentColorStr, radix: 16);
              final color = Color(colorValue);
              await accentPrefs.setAccentColor(color);
            }
          } catch (_) {
            // Ignorer les erreurs de parsing
          }
        }
      }

      // Player preferences
      if (_sl.isRegistered<PlayerPreferences>()) {
        final playerPrefs = _sl<PlayerPreferences>();
        final audioLang = prefs['preferred_audio_language']?.toString();
        if (audioLang != null) {
          await playerPrefs.setPreferredAudioLanguage(audioLang);
        }
        final subtitleLang = prefs['preferred_subtitle_language']?.toString();
        if (subtitleLang != null) {
          await playerPrefs.setPreferredSubtitleLanguage(subtitleLang);
        }
      }

      // Locale preferences
      if (_sl.isRegistered<LocalePreferences>()) {
        final localePrefs = _sl<LocalePreferences>();
        final locale = prefs['preferred_locale']?.toString();
        if (locale != null) {
          await localePrefs.setLanguageCode(locale);
        }
        final themeModeStr = prefs['theme_mode']?.toString();
        if (themeModeStr != null) {
          await localePrefs.setThemeMode(ThemeMode.dark);
        }
      }

      // Selected profile (on ne force pas, juste si pas déjà sélectionné)
      if (_sl.isRegistered<SelectedProfilePreferences>()) {
        final selectedProfilePrefs = _sl<SelectedProfilePreferences>();
        if (selectedProfilePrefs.selectedProfileId == null) {
          final selectedProfileId = _selectedProfileIdSanitizer.sanitize(
            prefs['selected_profile_id']?.toString(),
          );
          if (selectedProfileId != null && selectedProfileId.isNotEmpty) {
            await selectedProfilePrefs.setSelectedProfileId(selectedProfileId);
          }
        }
      }

      // Selected IPTV source
      if (_sl.isRegistered<SelectedIptvSourcePreferences>()) {
        final selectedIptvPrefs = _sl<SelectedIptvSourcePreferences>();
        final cloudRaw = prefs['selected_iptv_source_id']?.toString();
        final cloudId = cloudRaw?.trim();
        final current = selectedIptvPrefs.selectedSourceId?.trim();

        if (cloudId != null && cloudId.isNotEmpty) {
          if (knownIptvAccountIds == null) {
            if (current == null || current.isEmpty) {
              await selectedIptvPrefs.setSelectedSourceId(cloudId);
            }
          } else if (knownIptvAccountIds.contains(cloudId)) {
            final missingLocal = current == null || current.isEmpty;
            final staleLocal =
                current != null &&
                current.isNotEmpty &&
                !knownIptvAccountIds.contains(current);
            if (missingLocal || staleLocal) {
              await selectedIptvPrefs.setSelectedSourceId(cloudId);
            }
          }
        }
      }

      // IPTV sync interval
      if (_sl.isRegistered<IptvSyncPreferences>()) {
        final iptvSyncPrefs = _sl<IptvSyncPreferences>();
        final intervalMinutes = (prefs['iptv_sync_interval_minutes'] as num?)
            ?.toInt();
        if (intervalMinutes != null && intervalMinutes > 0) {
          await iptvSyncPrefs.setSyncInterval(
            Duration(minutes: intervalMinutes),
          );
        }
      }
    } catch (e, st) {
      assert(() {
        debugPrint(
          '[ComprehensiveCloudSyncService] pullUserPreferences failed: $e\n$st',
        );
        return true;
      }());
      // Ignorer les erreurs pour ne pas bloquer la sync
    }
  }

  String _stringifyThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
