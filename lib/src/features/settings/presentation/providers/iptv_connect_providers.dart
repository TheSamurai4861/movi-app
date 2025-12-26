import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
import 'package:movi/src/features/iptv/application/usecases/add_stalker_source.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/core/storage/storage.dart';

final addXtreamSourceProvider = Provider<AddXtreamSource>((ref) {
  final locator = ref.watch(slProvider);
  return locator<AddXtreamSource>();
});

final addStalkerSourceProvider = Provider<AddStalkerSource>((ref) {
  final locator = ref.watch(slProvider);
  return locator<AddStalkerSource>();
});

final refreshXtreamCatalogProvider = Provider<RefreshXtreamCatalog>((ref) {
  final locator = ref.watch(slProvider);
  return locator<RefreshXtreamCatalog>();
});
final refreshStalkerCatalogProvider = Provider<RefreshStalkerCatalog>((ref) {
  final locator = ref.watch(slProvider);
  return locator<RefreshStalkerCatalog>();
});

final supabaseIptvSourcesRepositoryProvider =
    Provider<SupabaseIptvSourcesRepository>((ref) {
      final locator = ref.watch(slProvider);
      return locator<SupabaseIptvSourcesRepository>();
    });

/// Politique de persistance Supabase lors d'un connect().
///
/// Objectif:
/// - rendre EXPLICITE si connect() fait "local only" ou "local + Supabase"
/// - éviter le cas: "0 source Supabase => welcomeSources" en boucle
enum IptvConnectSupabasePolicy {
  /// Connect() crée/active seulement le compte local.
  /// La persistance Supabase est gérée ailleurs (ex: WelcomeSourcePage).
  localOnly,

  /// Connect() tente d’écrire dans Supabase mais n’échoue pas si l’écriture échoue.
  /// (Risque: boucle possible si le bootstrap dépend du remote et qu’aucune autre couche ne persiste.)
  bestEffortSupabase,

  /// Connect() DO éviter la boucle: il ne renvoie "success" que si Supabase est garanti à la fin.
  /// (Recommandé si ton flow de navigation dépend directement de "0 sources Supabase => welcomeSources".)
  requireSupabase,
}

class IptvConnectState {
  const IptvConnectState({
    this.isLoading = false,
    this.error,
    this.warning,
    this.supabasePolicy = IptvConnectSupabasePolicy.requireSupabase,
  });

  final bool isLoading;

  /// Erreur bloquante (empêche le succès de la connexion).
  final String? error;

  /// Avertissement non bloquant (connexion OK mais sync Supabase échouée, etc.).
  final String? warning;

  /// Stratégie explicite: connect() persiste-t-il sur Supabase ?
  final IptvConnectSupabasePolicy supabasePolicy;

  static const _sentinel = Object();

  IptvConnectState copyWith({
    bool? isLoading,
    Object? error = _sentinel,
    Object? warning = _sentinel,
    IptvConnectSupabasePolicy? supabasePolicy,
  }) {
    return IptvConnectState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      warning: identical(warning, _sentinel)
          ? this.warning
          : warning as String?,
      supabasePolicy: supabasePolicy ?? this.supabasePolicy,
    );
  }
}

/// Contrôleur de connexion IPTV.
///
/// Objectif: clarifier le contrat de connect().
/// - Crée et active la source IPTV localement.
/// - Selon la policy, persiste (ou non) la source sur Supabase.
/// - Lance la synchronisation en arrière-plan.
/// - Évite les boucles de navigation si le bootstrap dépend de Supabase comme source-of-truth.
enum IptvSourceType { xtream, stalker }

class IptvConnectController extends Notifier<IptvConnectState> {
  late final AddXtreamSource _addXtream;
  late final AddStalkerSource _addStalker;
  late final RefreshXtreamCatalog _refreshXtream;
  late final RefreshStalkerCatalog _refreshStalker;
  late final IptvLocalRepository _iptvLocal;
  late final AppStateController _appState;
  late final SupabaseIptvSourcesRepository _supaSources;
  late final SelectedIptvSourcePreferences _selectedIptvPrefs;
  late final IptvCredentialsEdgeService _edgeCipher;

  @override
  IptvConnectState build() {
    _addXtream = ref.watch(addXtreamSourceProvider);
    _addStalker = ref.watch(addStalkerSourceProvider);
    _refreshXtream = ref.watch(refreshXtreamCatalogProvider);
    _refreshStalker = ref.watch(refreshStalkerCatalogProvider);
    _iptvLocal = ref.watch(slProvider)<IptvLocalRepository>();
    _appState = ref.watch(appStateControllerProvider);
    _supaSources = ref.watch(supabaseIptvSourcesRepositoryProvider);
    _selectedIptvPrefs = ref.watch(slProvider)<SelectedIptvSourcePreferences>();
    _edgeCipher = ref.watch(slProvider)<IptvCredentialsEdgeService>();

    // Par défaut, on choisit requireSupabase si:
    // - le bootstrap décide "welcomeSources" sur la base de Supabase (remote truth)
    // - sinon tu risques la boucle si l’écriture Supabase ne se fait pas ailleurs.
    return const IptvConnectState(
      supabasePolicy: IptvConnectSupabasePolicy.requireSupabase,
    );
  }

  void reset() {
    state = state.copyWith(isLoading: false, error: null, warning: null);
  }

  void setSupabasePolicy(IptvConnectSupabasePolicy policy) {
    state = state.copyWith(supabasePolicy: policy);
  }

  /// Connecte une source IPTV.
  ///
  /// Contrat explicite:
  /// - Toujours: crée/active une source localement (SQLite/vault).
  /// - Selon [state.supabasePolicy]:
  ///   - localOnly: ne touche pas Supabase
  ///   - bestEffortSupabase: tente l'upsert Supabase mais succès même si ça échoue
  ///   - requireSupabase: succès uniquement si l'upsert Supabase est confirmé
  Future<bool> connect({
    required IptvSourceType sourceType,
    required String serverUrl,
    String? username,
    String? password,
    String? macAddress,
    String? alias,
  }) async {
    final rawUrl = serverUrl.trim();
    final rawUser = username?.trim() ?? '';
    final rawPass = password ?? '';
    final rawAlias = alias?.trim();

    state = state.copyWith(isLoading: true, error: null, warning: null);

    try {
      String accountId;
      
      if (sourceType == IptvSourceType.xtream) {
        // 1) Ajouter localement via le usecase Xtream (SQLite + validation)
        if (rawUser.isEmpty || rawPass.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Nom d\'utilisateur et mot de passe requis pour Xtream',
          );
          return false;
        }

        final res = await _addXtream(
          serverUrl: rawUrl,
          username: rawUser,
          password: rawPass,
          alias: (rawAlias == null || rawAlias.isEmpty) ? null : rawAlias,
        );

        if (res.isErr()) {
          final message = res.fold<String>(ok: (_) => '', err: (f) => f.message);
          state = state.copyWith(isLoading: false, error: message);
          return false;
        }

        final XtreamAccount account = res.fold(
          ok: (a) => a,
          err: (_) => throw StateError('unreachable'),
        );

        accountId = account.id;

        // 2) Activer la source pour l'app
        _appState.addIptvSource(accountId);
        if ((_selectedIptvPrefs.selectedSourceId ?? '').isEmpty) {
          await _selectedIptvPrefs.setSelectedSourceId(accountId);
        }
        ref
            .read(appEventBusProvider)
            .emit(const AppEvent(AppEventType.iptvSynced));

        // 3) Persistance Supabase (selon policy)
        final policy = state.supabasePolicy;
        if (policy == IptvConnectSupabasePolicy.localOnly) {
          state = state.copyWith(
            isLoading: false,
            warning:
                'Connexion OK (local). Supabase non mis à jour (policy localOnly).',
          );
          unawaited(_runBackgroundSync(accountId));
          return true;
        }

        final supabaseOk = await _persistXtreamSourceToSupabase(
          account: account,
          serverUrl: rawUrl,
          username: rawUser,
          password: rawPass,
        );

        if (!supabaseOk) {
          if (policy == IptvConnectSupabasePolicy.requireSupabase) {
            state = state.copyWith(
              isLoading: false,
              error:
                  'Connexion IPTV OK, mais sauvegarde Supabase impossible. Réessaie (réseau/RLS/projet).',
            );
            return false;
          }
          state = state.copyWith(
            warning:
                "Connexion OK, mais sauvegarde Supabase échouée. La source peut ne pas être listée sur un nouvel appareil.",
          );
        }

        unawaited(_runBackgroundSync(accountId));
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        // Stalker
        if (macAddress == null || macAddress.trim().isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'Adresse MAC requise pour Stalker Portal',
          );
          return false;
        }

        final res = await _addStalker(
          serverUrl: rawUrl,
          macAddress: macAddress.trim(),
          username: rawUser.isEmpty ? null : rawUser,
          password: rawPass.isEmpty ? null : rawPass,
        );

        if (res.isErr()) {
          final message = res.fold<String>(ok: (_) => '', err: (f) => f.message);
          state = state.copyWith(isLoading: false, error: message);
          return false;
        }

        final StalkerAccount account = res.fold(
          ok: (a) => a,
          err: (_) => throw StateError('unreachable'),
        );

        accountId = account.id;

        // 2) Activer la source pour l'app
        _appState.addIptvSource(accountId);
        if ((_selectedIptvPrefs.selectedSourceId ?? '').isEmpty) {
          await _selectedIptvPrefs.setSelectedSourceId(accountId);
        }
        ref
            .read(appEventBusProvider)
            .emit(const AppEvent(AppEventType.iptvSynced));

        // Pour Stalker, on ne persiste pas encore sur Supabase (à implémenter si nécessaire)
        state = state.copyWith(isLoading: false);
        unawaited(_runBackgroundSync(accountId));
        return true;
      }

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Persiste la source Xtream dans Supabase.
  ///
  /// Retour:
  /// - true  => upsert confirmé (garantie ">=1 source Supabase")
  /// - false => upsert non garanti (auth non résolu / erreur Supabase / timeout)
  Future<bool> _persistXtreamSourceToSupabase({
    required XtreamAccount account,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    // Recommandé : utiliser l'userId issu de l'auth state (évite dépendance
    // à Supabase.auth.currentUser qui peut être null au tout début du boot).
    final userId = ref.read(authUserIdProvider);

    if (userId == null || userId.trim().isEmpty) {
      // Impossible de garantir l’écriture remote.
      if (kDebugMode) {
        debugPrint(
          '[IptvConnectController] Cannot persist Supabase: authUserIdProvider is null/empty.',
        );
      }
      return false;
    }

    final resolvedUserId = userId.trim();

    final String displayName = account.alias.trim().isNotEmpty
        ? account.alias.trim()
        : 'Xtream';

    // IMPORTANT:
    // - `account.id` est un identifiant LOCAL (string) -> on le mappe sur `local_id`
    // - `iptv_sources.id` côté Supabase reste un UUID (généré par Supabase)
    // - upsert se fait sur UNIQUE(account_id, local_id)
    final String localId = account.id;

    try {
      String? encryptedCredentials;
      try {
        encryptedCredentials = await _edgeCipher
            .encrypt(
              username: username,
              password: password,
            )
            .timeout(const Duration(seconds: 5));
        if (kDebugMode) {
          debugPrint(
            '[IptvConnectController] Edge function encrypt succeeded',
          );
        }
      } catch (e) {
        // If the Edge Function isn't deployed yet, we still persist metadata so
        // bootstrap can proceed. Multi-device password reuse will not work
        // until the Edge Function is set up.
        if (kDebugMode) {
          debugPrint(
            '[IptvConnectController] Edge function encrypt failed: $e. Continuing without encrypted credentials.',
          );
        }
        encryptedCredentials = null;
      }

      await _supaSources
          .upsertSource(
            localId: localId,
            accountId: resolvedUserId,
            name: displayName,
            expiresAt: account.expirationDate,
            serverUrl: serverUrl,
            username: username,
            encryptedCredentials: encryptedCredentials,
            // Optionnel si ton schéma l'a:
            // isActive: true,
            // lastSyncAt: null,
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint(
          '[IptvConnectController] Supabase iptv_sources upsert succeeded for localId=$localId',
        );
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[IptvConnectController] Supabase iptv_sources upsert failed: $e\n$st',
        );
        debugPrint(
          '[IptvConnectController] Details: localId=$localId, accountId=$resolvedUserId, serverUrl=$serverUrl',
        );
      }
      return false;
    }
  }

  Future<void> _runBackgroundSync(String accountId) async {
    try {
      final locator = ref.read(slProvider);
      if (locator.isRegistered<PerformanceTuning>()) {
        final tuning = locator<PerformanceTuning>();
        if (tuning.iptvConnectSyncDelay > Duration.zero) {
          await Future<void>.delayed(tuning.iptvConnectSyncDelay);
        }
      }
      final stalkerAccount = await _iptvLocal.getStalkerAccount(accountId);
      final res = stalkerAccount != null
          ? await _refreshStalker(accountId)
          : await _refreshXtream(accountId);
      if (res.isErr()) return;

      ref
          .read(appEventBusProvider)
          .emit(const AppEvent(AppEventType.iptvSynced));
    } catch (_) {
      // best-effort
    }
  }
}

final iptvConnectControllerProvider =
    NotifierProvider<IptvConnectController, IptvConnectState>(
      IptvConnectController.new,
    );
