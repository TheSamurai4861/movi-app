// lib/src/core/network/config/network_module.dart
import 'package:dio/dio.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';

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
