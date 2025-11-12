import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/network_executor.dart';
import '../../../../core/network/dio_failure_mapper.dart';
import '../../../../core/network/network_failures.dart';
import '../../../../core/iptv/domain/value_objects/xtream_endpoint.dart';

/// État minimal pour l'écran Welcome (UI uniquement)
class WelcomeUiState {
  const WelcomeUiState({
    this.isTesting = false,
    this.isObscured = true,
    this.errorMessage,
    this.endpointPreview,
  });

  final bool isTesting;
  final bool isObscured;
  final String? errorMessage;
  final String? endpointPreview;

  WelcomeUiState copyWith({
    bool? isTesting,
    bool? isObscured,
    String? errorMessage, // passer explicitement null pour effacer
    String? endpointPreview,
  }) {
    return WelcomeUiState(
      isTesting: isTesting ?? this.isTesting,
      isObscured: isObscured ?? this.isObscured,
      errorMessage: errorMessage,
      endpointPreview: endpointPreview,
    );
  }
}

/// Contrôleur UI pour Welcome
class WelcomeController extends StateNotifier<WelcomeUiState> {
  WelcomeController(this._dio) : super(const WelcomeUiState());

  final Dio _dio;

  void toggleObscure() {
    state = state.copyWith(isObscured: !state.isObscured);
  }

  /// Met à jour l’aperçu de l’endpoint en validant l’URL (sans lever d’exception UI)
  void updateUrlPreview(String raw) {
    final ep = XtreamEndpoint.tryParse(raw);
    state = state.copyWith(endpointPreview: ep?.toRawUrl(), errorMessage: null);
  }

  /// Teste la connexion Xtream sans rien créer dans l’app (ping rapide).
  /// S’appuie sur NetworkExecutor pour map les erreurs Dio -> Failures propres.
  Future<bool> testConnection({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (state.isTesting) return false;
    state = state.copyWith(isTesting: true, errorMessage: null);

    try {
      final endpoint = XtreamEndpoint.parse(serverUrl);
      final uri = endpoint.buildUri({
        'username': username,
        'password': password,
      });

      final executor = NetworkExecutor(_dio);
      // On ne se fie pas au shape exact du JSON (fournisseurs variés) :
      // succès HTTP + corps non nul = OK
      final ok = await executor.run<dynamic, bool>(
        request: (c) => c.getUri<dynamic>(uri),
        mapper: (_) => true,
      );

      state = state.copyWith(isTesting: false, errorMessage: null);
      return ok;
    } on NetworkFailure catch (f) {
      state = state.copyWith(isTesting: false, errorMessage: f.message);
      return false;
    } on DioException catch (e) {
      final f = mapDioToFailure(e);
      state = state.copyWith(isTesting: false, errorMessage: f.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isTesting: false,
        errorMessage: 'Erreur inattendue',
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

/// Fournit un Dio depuis le conteneur d’injection (network_module)
final _dioProvider = Provider<Dio>((ref) => sl<Dio>());

/// Provider principal du contrôleur UI
final welcomeControllerProvider =
    StateNotifierProvider<WelcomeController, WelcomeUiState>(
      (ref) => WelcomeController(ref.watch(_dioProvider)),
    );
