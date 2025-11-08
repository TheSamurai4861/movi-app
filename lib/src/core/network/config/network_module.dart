import 'package:dio/dio.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';

import '../../config/models/app_config.dart';
import '../../config/services/secret_store.dart';
import '../../di/injector.dart';
import '../../utils/logger.dart';
import '../http_client_factory.dart';
import '../network_executor.dart';
import '../interceptors/locale_interceptor.dart';

class NetworkModule {
  static void register({LocaleCodeProvider? localeProvider}) {
    if (sl.isRegistered<NetworkExecutor>()) return;

    if (!sl.isRegistered<AppConfig>()) {
      throw StateError('AppConfig must be registered before NetworkModule.');
    }
    if (!sl.isRegistered<TmdbCacheDataSource>()) {
      sl.registerLazySingleton<TmdbCacheDataSource>(
        () => TmdbCacheDataSource(sl<ContentCacheRepository>()),
      );
    }

    final config = sl<AppConfig>();
    final logger = sl<AppLogger>();
    final secretStore = sl<SecretStore>();

    final factory = HttpClientFactory(
      config: config,
      logger: logger,
      secretStore: secretStore,
      localeProvider: localeProvider,
    );

    final dio = factory.create();
    sl.registerSingleton<Dio>(dio);
    sl.registerSingleton<NetworkExecutor>(NetworkExecutor(dio, logger: logger));
  }
}
