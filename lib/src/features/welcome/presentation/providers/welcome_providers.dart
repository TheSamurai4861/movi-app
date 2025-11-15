import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/features/iptv/iptv.dart';

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
class WelcomeController extends Notifier<WelcomeUiState> {
  late final Dio _dio;

  @override
  WelcomeUiState build() {
    _dio = ref.watch(welcomeDioProvider);
    return const WelcomeUiState();
  }

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
        request: (c, token) => c.getUri<dynamic>(
          uri,
          cancelToken: token,
        ),
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
final welcomeDioProvider = Provider<Dio>((ref) {
  final locator = ref.watch(slProvider);
  return locator<Dio>();
});

/// Provider principal du contrôleur UI
final welcomeControllerProvider =
    NotifierProvider<WelcomeController, WelcomeUiState>(WelcomeController.new);
