// lib/src/core/network/http_client_factory.dart
import 'package:dio/dio.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';

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
      // N'autorise pas les 200-299 uniquement, le mapper gérera l'erreur typée.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 600,
    );

    final dio = Dio(options);

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
