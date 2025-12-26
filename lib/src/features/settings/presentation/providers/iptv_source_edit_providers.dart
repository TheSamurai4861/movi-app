import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';

final iptvAccountByIdProvider =
    FutureProvider.family<XtreamAccount?, String>((ref, accountId) async {
      final local = ref.watch(slProvider)<IptvLocalRepository>();
      final accounts = await local.getAccounts();
      for (final account in accounts) {
        if (account.id == accountId) return account;
      }
      return null;
    });

final iptvAccountPasswordProvider =
    FutureProvider.family<String?, String>((ref, accountId) async {
      final vault = ref.watch(slProvider)<CredentialsVault>();
      return vault.readPassword(accountId);
    });

class IptvSourceEditState {
  const IptvSourceEditState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  IptvSourceEditState copyWith({bool? isLoading, String? error}) =>
      IptvSourceEditState(isLoading: isLoading ?? this.isLoading, error: error);
}

/// Contrôleur de modification d'une source IPTV.
///
/// - Valide la source via `AddXtreamSource` (auth + persistance compte+mdp).
/// - Si l'identifiant de compte change, remplace l'ancien compte (DB + vault)
///   et met à jour la liste des sources actives si nécessaire.
/// - Lance ensuite un refresh de catalogue en arrière-plan.
class IptvSourceEditController extends Notifier<IptvSourceEditState> {
  late final AddXtreamSource _add;
  late final RefreshXtreamCatalog _refresh;
  late final AppStateController _appState;
  late final IptvLocalRepository _local;
  late final CredentialsVault _vault;
  late final SupabaseIptvSourcesRepository _supaSources;
  late final IptvCredentialsEdgeService _edgeCipher;

  @override
  IptvSourceEditState build() {
    final sl = ref.watch(slProvider);
    _add = sl<AddXtreamSource>();
    _refresh = sl<RefreshXtreamCatalog>();
    _local = sl<IptvLocalRepository>();
    _vault = sl<CredentialsVault>();
    _supaSources = sl<SupabaseIptvSourcesRepository>();
    _edgeCipher = sl<IptvCredentialsEdgeService>();
    _appState = ref.watch(asp.appStateControllerProvider);
    return const IptvSourceEditState();
  }

  void reset() {
    state = const IptvSourceEditState();
  }

  Future<bool> submit({
    required String originalAccountId,
    required String serverUrl,
    required String username,
    required String password,
    String? alias,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _add(
        serverUrl: serverUrl,
        username: username,
        password: password,
        alias: alias,
      );

      if (res.isErr()) {
        final message = res.fold<String>(ok: (_) => '', err: (f) => f.message);
        state = state.copyWith(isLoading: false, error: message);
        return false;
      }

      final account = res.fold(
        ok: (a) => a,
        err: (_) => throw StateError('unreachable'),
      );

      final oldId = originalAccountId.trim();
      final newId = account.id;
      final wasActive = ref.read(asp.activeIptvSourcesProvider).contains(oldId);

      if (oldId.isNotEmpty && oldId != newId) {
        if (wasActive) {
          _appState.removeIptvSource(oldId);
          _appState.addIptvSource(newId);
        }
        await _local.removeAccount(oldId);
        await _vault.removePassword(oldId);
      } else if (wasActive) {
        _appState.addIptvSource(newId);
      }

      // Best-effort Supabase sync (keep remote metadata + encrypted credentials aligned).
      unawaited(
        _syncSupabase(
          originalLocalId: oldId,
          account: account,
          serverUrl: serverUrl.trim(),
          username: username.trim(),
          password: password,
        ),
      );

      ref.invalidate(iptvAccountsProvider);
      ref.invalidate(iptvSourceStatsProvider(newId));

      unawaited(_runBackgroundSync(newId));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> _runBackgroundSync(String accountId) async {
    try {
      final res = await _refresh(accountId);
      if (res.isErr()) return;

      ref.invalidate(iptvSourceStatsProvider(accountId));
      ref
          .read(appEventBusProvider)
          .emit(const AppEvent(AppEventType.iptvSynced));
    } catch (_) {}
  }

  Future<void> _syncSupabase({
    required String originalLocalId,
    required XtreamAccount account,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final userId = ref.read(authUserIdProvider);
    if (userId == null || userId.trim().isEmpty) return;
    final resolvedUserId = userId.trim();

    try {
      String? encryptedCredentials;
      try {
        encryptedCredentials = await _edgeCipher.encrypt(
          username: username,
          password: password,
        );
      } catch (_) {
        encryptedCredentials = null;
      }

      await _supaSources.upsertSource(
        localId: account.id,
        accountId: resolvedUserId,
        name: account.alias,
        expiresAt: account.expirationDate,
        serverUrl: serverUrl,
        username: username,
        encryptedCredentials: encryptedCredentials,
      );

      // Si l'identifiant local a changé, supprimer l'ancienne ligne remote (best-effort).
      final oldLocalId = originalLocalId.trim();
      if (oldLocalId.isNotEmpty && oldLocalId != account.id) {
        final rows = await _supaSources.getSources(accountId: resolvedUserId);
        for (final r in rows) {
          if ((r.localId ?? '').trim() == oldLocalId) {
            await _supaSources.deleteSource(id: r.id, accountId: resolvedUserId);
            break;
          }
        }
      }
    } catch (_) {
      // best-effort
    }
  }
}

final iptvSourceEditControllerProvider =
    NotifierProvider<IptvSourceEditController, IptvSourceEditState>(
      IptvSourceEditController.new,
    );
