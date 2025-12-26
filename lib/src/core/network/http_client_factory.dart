// lib/src/core/network/http_client_factory.dart
import 'package:dio/dio.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/network/proxy/dio_proxy.dart' as dio_proxy;

class HttpClientFactory {
  const HttpClientFactory({
    required this.config,
    required this.logger,
    this.localeProvider,
    this.authTokenProvider,
  });

  final AppConfig config;
  final AppLogger logger;
  final LocaleCodeProvider? localeProvider;
  final AuthTokenProvider? authTokenProvider;

  Dio create() {
    final baseUrl = config.network.restBaseUrl.trim();
    final options = BaseOptions(
      baseUrl: baseUrl.isNotEmpty == true ? baseUrl : '',
      connectTimeout: config.network.timeouts.connect,
      receiveTimeout: config.network.timeouts.receive,
      sendTimeout: config.network.timeouts.send,
      responseType: ResponseType.json,
      followRedirects: true,
      headers: <String, Object?>{
        'Accept': 'application/json',
        'User-Agent':
            'MOVI/${config.metadata.version} (${config.environment.label})',
      },
      // Laisse Dio lever une `DioExceptionType.badResponse` sur 4xx/5xx.
      // Le mapping typé (NetworkFailure) est géré ensuite par l'exécuteur.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    );

    final dio = Dio(options);

    // Optional proxy support (useful on corporate networks / restricted devices).
    dio_proxy.configureDioProxyFromEnvironment(dio, logger: logger);

    dio.interceptors.addAll(<Interceptor>[
      if (authTokenProvider != null)
        AuthInterceptor(
          tokenProvider: authTokenProvider!,
          logger: logger,
          dio: dio,
        ),
      LocaleInterceptor(localeProvider: localeProvider),
      RetryInterceptor(dio: dio, logger: logger),
      TelemetryInterceptor(
        logger: logger,
        enabled: config.featureFlags.telemetry.enableTelemetry,
      ),
    ]);

    return dio;
  }
}
