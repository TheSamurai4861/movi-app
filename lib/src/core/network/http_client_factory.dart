import 'package:dio/dio.dart';

import '../config/services/secret_store.dart';
import '../config/models/app_config.dart';
import '../utils/logger.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/locale_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/telemetry_interceptor.dart';

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
    final dio = Dio(
      BaseOptions(
        baseUrl: config.network.restBaseUrl,
        connectTimeout: config.network.timeouts.connect,
        receiveTimeout: config.network.timeouts.receive,
        sendTimeout: config.network.timeouts.send,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MOVI/${config.metadata.version} (${config.environment.label})',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenResolver: () async => config.network.tmdbApiKey ?? await secretStore.read('TMDB_API_KEY'),
      ),
      LocaleInterceptor(localeProvider: localeProvider),
      RetryInterceptor(dio: dio, logger: logger),
      TelemetryInterceptor(logger: logger),
    ]);

    return dio;
  }
}
