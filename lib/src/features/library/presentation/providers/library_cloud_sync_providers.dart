import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/storage/storage.dart';
// ignore: unnecessary_import
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';
import 'package:movi/src/features/library/application/services/library_cloud_sync_service.dart';
import 'package:movi/src/features/library/application/services/comprehensive_cloud_sync_service.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

@immutable
class LibraryCloudSyncState {
  const LibraryCloudSyncState({
    required this.autoSyncEnabled,
    this.isSyncing = false,
    this.lastSuccessAtUtc,
    this.lastError,
  });

  final bool autoSyncEnabled;
  final bool isSyncing;
  final DateTime? lastSuccessAtUtc;
  final String? lastError;

  LibraryCloudSyncState copyWith({
    bool? autoSyncEnabled,
    bool? isSyncing,
    DateTime? lastSuccessAtUtc,
    bool clearLastSuccessAt = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return LibraryCloudSyncState(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSuccessAtUtc:
          clearLastSuccessAt ? null : lastSuccessAtUtc ?? this.lastSuccessAtUtc,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }
}

final libraryCloudSyncServiceProvider = Provider<LibraryCloudSyncService>((ref) {
  final locator = ref.watch(slProvider);
  return LibraryCloudSyncService(
    secureStorage: locator<SecureStorageRepository>(),
    outbox: locator<SyncOutboxRepository>(),
    db: locator<Database>(),
    playlistLocal: locator<PlaylistLocalRepository>(),
  );
});

final comprehensiveCloudSyncServiceProvider =
    Provider<ComprehensiveCloudSyncService>((ref) {
  final locator = ref.watch(slProvider);
  return ComprehensiveCloudSyncService(
    sl: locator,
    librarySync: ref.watch(libraryCloudSyncServiceProvider),
  );
});

class LibraryCloudSyncController extends Notifier<LibraryCloudSyncState> {
  Timer? _debounce;
  int _syncToken = 0;
  StreamSubscription<bool>? _autoSyncSub;
  bool _listenersAttached = false;

  static const Duration _autoSyncDebounce = Duration(milliseconds: 600);
  static const Duration _minIntervalBetweenAutoSync = Duration(seconds: 30);

  DateTime? _lastAutoSyncAttemptUtc;

  @override
  LibraryCloudSyncState build() {
    final locator = ref.watch(slProvider);
    final prefs = locator<CloudSyncPreferences>();

    ref.onDispose(() {
      _debounce?.cancel();
      _autoSyncSub?.cancel();
    });

    // Keep state aligned with the preference stream.
    _autoSyncSub ??= prefs.autoSyncEnabledStreamWithInitial.listen((enabled) {
      state = state.copyWith(autoSyncEnabled: enabled);
    });

    // Auto-sync triggers: profile selection and Supabase availability.
    if (!_listenersAttached) {
      _listenersAttached = true;
      ref.listen<String?>(
        selectedProfileIdProvider,
        (_, __) => _scheduleAutoSync(),
      );
      ref.listen(
        supabaseClientProvider,
        (_, __) => _scheduleAutoSync(),
      );
    }

    return LibraryCloudSyncState(autoSyncEnabled: prefs.autoSyncEnabled);
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final locator = ref.read(slProvider);
    final prefs = locator<CloudSyncPreferences>();
    await prefs.setAutoSyncEnabled(enabled);
    state = state.copyWith(autoSyncEnabled: enabled);
  }

  void _scheduleAutoSync() {
    if (!state.autoSyncEnabled) return;

    final now = DateTime.now().toUtc();
    if (_lastAutoSyncAttemptUtc != null &&
        now.difference(_lastAutoSyncAttemptUtc!) < _minIntervalBetweenAutoSync) {
      return;
    }
    _lastAutoSyncAttemptUtc = now;

    _debounce?.cancel();
    _debounce = Timer(_autoSyncDebounce, () {
      unawaited(syncNow(reason: 'auto'));
    });
  }

  String _formatErrorForUi(Object error) {
    var message = error.toString().trim();

    final uriIndex = message.indexOf(', uri=');
    if (uriIndex != -1) {
      message = message.substring(0, uriIndex).trim();
    }

    // Common offline/DNS cases (do not rely on dart:io types to keep web-safe).
    final lower = message.toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('host is down') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('timed out')) {
      return 'Réseau indisponible.';
    }

    if (message.isEmpty) return 'Erreur inconnue.';
    return message;
  }

  Future<void> syncNow({String reason = 'manual'}) async {
    final profileId = ref.read(selectedProfileIdProvider)?.trim();
    final client = ref.read(supabaseClientProvider);

    if (profileId == null || profileId.isEmpty) {
      if (reason == 'manual') {
        state = state.copyWith(lastError: 'Aucun profil sélectionné.');
      }
      return;
    }
    if (client == null) {
      if (reason == 'manual') {
        state = state.copyWith(lastError: 'Supabase indisponible.');
      }
      return;
    }
    if (state.isSyncing) return;

    // Cancel any in-flight sync when a new one starts.
    final token = ++_syncToken;

    state = state.copyWith(isSyncing: true, clearLastError: true);

    final comprehensiveService = ref.read(comprehensiveCloudSyncServiceProvider);
    final sl = ref.read(slProvider);

    bool shouldCancel() {
      if (token != _syncToken) return true;
      final currentProfile = ref.read(selectedProfileIdProvider)?.trim();
      return currentProfile == null || currentProfile != profileId;
    }

    try {
      if (reason == 'manual') {
        // Best-effort: refresh profiles + IPTV sources/catalog in the same "Sync now"
        // action so the Settings screen updates everything in one tap.
        try {
          await ref.read(profilesControllerProvider.notifier).refresh();
        } catch (_) {
          // best-effort
        }
        try {
          await _syncIptvSourcesAndCatalog(sl: sl, client: client);
        } catch (_) {
          // best-effort
        }
      }

      // Utiliser le service de synchronisation complète qui gère tout
      await comprehensiveService.syncAll(
        client: client,
        profileId: profileId,
        shouldCancel: shouldCancel,
      );

      if (shouldCancel()) return;

      // Pull les préférences depuis Supabase (après le push)
      await comprehensiveService.pullUserPreferences(
        client: client,
        shouldCancel: shouldCancel,
      );

      state = state.copyWith(
        isSyncing: false,
        lastSuccessAtUtc: DateTime.now().toUtc(),
        clearLastError: true,
      );

      ref.invalidate(libraryPlaylistsProvider);
      ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.librarySynced));
    } catch (e, st) {
      assert(() {
        debugPrint('[LibraryCloudSyncController] sync($reason) failed: $e\n$st');
        return true;
      }());
      if (shouldCancel()) return;
      state = state.copyWith(
        isSyncing: false,
        lastError: _formatErrorForUi(e),
      );
    } finally {
      if (!shouldCancel()) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }

  Future<void> _syncIptvSourcesAndCatalog({
    required GetIt sl,
    required SupabaseClient client,
  }) async {
    final uid = client.auth.currentSession?.user.id.trim();
    if (uid == null || uid.isEmpty) return;

    if (!sl.isRegistered<SupabaseIptvSourcesRepository>()) return;
    if (!sl.isRegistered<IptvCredentialsEdgeService>()) return;
    if (!sl.isRegistered<IptvLocalRepository>()) return;
    if (!sl.isRegistered<CredentialsVault>()) return;

    final sourcesRepo = sl<SupabaseIptvSourcesRepository>();
    final edge = sl<IptvCredentialsEdgeService>();
    final localRepo = sl<IptvLocalRepository>();
    final vault = sl<CredentialsVault>();

    final sources = await sourcesRepo.getSources(accountId: uid);
    if (sources.isEmpty) return;

    var hydrated = 0;
    for (final s in sources) {
      var serverUrl = s.serverUrl?.trim();
      final username = s.username?.trim();
      final ciphertext = s.encryptedCredentials?.trim();

      if (serverUrl == null ||
          serverUrl.isEmpty ||
          username == null ||
          username.isEmpty ||
          ciphertext == null ||
          ciphertext.isEmpty) {
        continue;
      }

      // Détecter et corriger les URLs invalides stockées avec toString() au lieu de toRawUrl()
      // Si l'URL contient "XtreamEndpoint" ou commence par "Instance of", c'est invalide
      if (serverUrl.contains('XtreamEndpoint') || 
          serverUrl.startsWith('Instance of')) {
        if (kDebugMode) {
          debugPrint(
            '[LibraryCloudSync] Invalid serverUrl format detected for source ${s.id}: "$serverUrl". '
            'This source cannot be hydrated. Please reconnect it manually.',
          );
        }
        continue;
      }

      final endpoint = XtreamEndpoint.tryParse(serverUrl);
      if (endpoint == null) {
        if (kDebugMode) {
          debugPrint(
            '[LibraryCloudSync] Failed to parse serverUrl for source ${s.id}: "$serverUrl"',
          );
        }
        continue;
      }

      final payload = await edge.decrypt(ciphertext: ciphertext);
      final pw = payload.password.trim();
      if (pw.isEmpty) continue;

      final localId =
          (s.localId?.trim().isNotEmpty ?? false)
              ? s.localId!.trim()
              : '${endpoint.host}_${payload.username}'.toLowerCase();

      final account = XtreamAccount(
        id: localId,
        alias: (s.name.trim().isNotEmpty) ? s.name.trim() : endpoint.host,
        endpoint: endpoint,
        username: payload.username.trim(),
        status: XtreamAccountStatus.pending,
        createdAt: DateTime.now(),
        expirationDate: s.expiresAt,
        lastError: null,
      );

      await localRepo.saveAccount(account);
      await vault.storePassword(localId, pw);
      hydrated += 1;
    }

    if (hydrated <= 0) return;

    // Ensure one active source + persist selection if missing.
    final selectedPrefs = sl.isRegistered<SelectedIptvSourcePreferences>()
        ? sl<SelectedIptvSourcePreferences>()
        : null;
    final accounts = await localRepo.getAccounts();
    if (accounts.isEmpty) return;

    final controller = ref.read(appStateControllerProvider);
    final existing = ref.read(appStateProvider).activeIptvSources;
    if (existing.isEmpty) {
      final preferred = selectedPrefs?.selectedSourceId?.trim();
      String chosen;
      if (preferred != null && accounts.any((a) => a.id == preferred)) {
        chosen = preferred;
      } else {
        chosen = accounts.first.id;
      }
      await selectedPrefs?.setSelectedSourceId(chosen);
      controller.setActiveIptvSources({chosen});
    }

    // Refresh IPTV catalog (best-effort) so Home updates right after sync.
    if (sl.isRegistered<RefreshXtreamCatalog>()) {
      final refresh = sl<RefreshXtreamCatalog>();
      final active = ref.read(appStateProvider).activeIptvSources;
      for (final id in active) {
        try {
          await refresh(id);
        } catch (_) {}
      }
      ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
    }
  }
}

final libraryCloudSyncControllerProvider =
    NotifierProvider<LibraryCloudSyncController, LibraryCloudSyncState>(
      LibraryCloudSyncController.new,
    );
