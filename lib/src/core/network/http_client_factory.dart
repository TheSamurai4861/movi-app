// lib/src/core/network/http_client_factory.dart
import 'package:dio/dio.dart';

import '../config/models/app_config.dart';
import '../config/services/secret_store.dart';
import '../utils/logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/locale_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/telemetry_interceptor.dart';

typedef LocaleCodeProvider = String? Function();

class HttpClientFactory {
  const HttpClientFactory({
    required this.config,
    required this.logger,
    required this.secretStore,
    this.localeProvider,
  });

  final AppConfig config;
  final AppLogger logger;
  final SecretStore secretStore;
  final LocaleCodeProvider? localeProvider;

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
      validateStatus: (status) => status != null && status >= 200 && status < 600,
    );

    final dio = Dio(options);

    dio.interceptors.addAll(<Interceptor>[
      AuthInterceptor(
        tokenResolver: () async =>
            config.network.tmdbApiKey ?? await secretStore.read('TMDB_API_KEY'),
      ),
      LocaleInterceptor(localeProvider: localeProvider),
      RetryInterceptor(dio: dio, logger: logger),
      TelemetryInterceptor(logger: logger),
    ]);

    return dio;
  }
}
