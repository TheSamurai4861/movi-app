// lib/src/features/settings/presentation/providers/iptv_connect_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';

class IptvConnectState {
  const IptvConnectState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;

  IptvConnectState copyWith({bool? isLoading, String? error}) =>
      IptvConnectState(isLoading: isLoading ?? this.isLoading, error: error);
}

/// Contrôleur de connexion IPTV.
/// Objectif : **ne pas bloquer la navigation**.
/// - Crée et active la source IPTV.
/// - Lance la synchronisation **en arrière-plan** (fire-and-forget).
/// - À la fin de la synchro, déclenche un refresh de la Home.
class IptvConnectController extends StateNotifier<IptvConnectState> {
  IptvConnectController(this._add, this._refresh, this._appState, this._ref)
    : super(const IptvConnectState());

  final AddXtreamSource _add;
  final RefreshXtreamCatalog _refresh;
  final AppStateController _appState;
  final Ref _ref;

  Future<bool> connect({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _add(
        serverUrl: serverUrl,
        username: username,
        password: password,
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

      // 2) Activer la source pour l’app (si logique d’état globale)
      _appState.addIptvSource(account.id);

      // 3) Synchroniser le catalogue **sans bloquer l’UI**
      unawaited(_runBackgroundSync(account.id));

      // 4) Rendre la main immédiatement pour permettre la navigation vers Home
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
      if (res.isErr()) {
        return;
      }
      // Une fois la synchro terminée, on rafraîchit la Home.
      await _ref.read(homeControllerProvider.notifier).refresh();
    } catch (_) {
      // On ignore ici les erreurs de background pour ne pas perturber l’UI.
      // (Elles pourront être remontées par la Home si nécessaire.)
    }
  }
}

final iptvConnectControllerProvider =
    StateNotifierProvider<IptvConnectController, IptvConnectState>(
      (ref) => IptvConnectController(
        sl<AddXtreamSource>(),
        sl<RefreshXtreamCatalog>(),
        sl<AppStateController>(),
        ref,
      ),
    );
