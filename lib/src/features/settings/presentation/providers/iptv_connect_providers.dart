// lib/src/features/settings/presentation/providers/iptv_connect_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/iptv/application/usecases/add_xtream_source.dart';
import '../../../../core/iptv/application/usecases/refresh_xtream_catalog.dart';
import '../../../../core/state/app_state_controller.dart';
import '../../../home/presentation/providers/home_providers.dart';

class IptvConnectState {
  const IptvConnectState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;

  IptvConnectState copyWith({bool? isLoading, String? error}) =>
      IptvConnectState(isLoading: isLoading ?? this.isLoading, error: error);
}

class IptvConnectController extends StateNotifier<IptvConnectState> {
  IptvConnectController(this._add, this._refresh, this._appState, this._ref)
      : super(const IptvConnectState());

  final AddXtreamSource _add;
  final RefreshXtreamCatalog _refresh;
  final AppStateController _appState;
  final Ref _ref;

  /// Crée la source IPTV, l’active, synchronise le catalogue puis
  /// déclenche un refresh de la Home (qui utilisera le chargement paresseux).
  Future<bool> connect({
    required String serverUrl,
    required String username,
    required String password,
    required String alias,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1) Créer la source
      final account = await _add(
        serverUrl: serverUrl,
        username: username,
        password: password,
        alias: alias,
      );

      // 2) Activer la source pour l’app (au cas où AppState ne le ferait pas déjà)
      _appState.addIptvSource(account.id);

      // 3) Synchroniser le catalogue
      await _refresh(account.id);

      // 4) Rafraîchir la Home (iptvLists seront peuplées puis enrichies à la volée)
      await _ref.read(homeControllerProvider.notifier).refresh();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
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
