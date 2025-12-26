import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/features/iptv/iptv.dart';
import 'package:movi/src/features/welcome/presentation/utils/error_presenter.dart';

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
    bool clearErrorMessage = false,
    bool clearEndpointPreview = false,
    String? errorMessage,
    String? endpointPreview,
  }) {
    return WelcomeUiState(
      isTesting: isTesting ?? this.isTesting,
      isObscured: isObscured ?? this.isObscured,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      endpointPreview:
          clearEndpointPreview ? null : (endpointPreview ?? this.endpointPreview),
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
    state = state.copyWith(
      endpointPreview: ep?.toRawUrl(),
      clearEndpointPreview: ep == null,
      clearErrorMessage: true,
    );
  }

  /// Teste la connexion Xtream sans rien créer dans l’app (ping rapide).
  /// S’appuie sur NetworkExecutor pour map les erreurs Dio -> Failures propres.
  Future<bool> testConnection({
    required BuildContext context,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (state.isTesting) return false;
    state = state.copyWith(isTesting: true, clearErrorMessage: true);
    final l10n = AppLocalizations.of(context);

    try {
      final endpoint = XtreamEndpoint.parse(serverUrl);
      final uri = endpoint.buildUri({
        'username': username,
        'password': password,
      });

      final executor = NetworkExecutor(_dio);
      final ok = await executor.run<dynamic, bool>(
        request: (c, token) => c.getUri<dynamic>(uri, cancelToken: token),
        mapper: (_) => true,
      );

      state = state.copyWith(isTesting: false, clearErrorMessage: true);
      return ok;
    } on NetworkFailure catch (f) {
      state = state.copyWith(
        isTesting: false,
        errorMessage:
            l10n != null ? presentFailureL10n(l10n, f) : 'Unknown error',
      );
      return false;
    } on DioException catch (e) {
      final f = mapDioToFailure(e);
      state = state.copyWith(
        isTesting: false,
        errorMessage:
            l10n != null ? presentFailureL10n(l10n, f) : 'Unknown error',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isTesting: false,
        errorMessage: l10n?.errorUnknown ?? 'Unknown error',
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearErrorMessage: true);
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
