// lib/src/core/network/config/network_module.dart
import 'package:dio/dio.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';

class NetworkModule {
  static void register({
    LocaleCodeProvider? localeProvider,
    AuthTokenProvider? authTokenProvider,
  }) {
    if (!sl.isRegistered<AppConfig>()) {
      throw StateError('AppConfig must be registered before NetworkModule.');
    }

    final config = sl<AppConfig>();
    final logger = sl<AppLogger>();

    final factory = HttpClientFactory(
      config: config,
      logger: logger,
      localeProvider: localeProvider,
      authTokenProvider: authTokenProvider,
    );

    final dio = factory.create();
    _replaceSingleton<Dio>(dio, (old) => old.close(force: true));
    _replaceSingleton<NetworkExecutor>(
      NetworkExecutor(
        dio,
        logger: logger,
        defaultMaxConcurrent: 12, // Augmenté de 6 à 12 pour éviter les blocages
        limiterAcquireTimeout: const Duration(seconds: 10), // Timeout augmenté pour réduire les échecs
      ),
      (old) => old.dispose(),
    );
  }

  static void _replaceSingleton<T extends Object>(
    T instance,
    void Function(T old)? dispose,
  ) {
    if (sl.isRegistered<T>()) {
      final old = sl<T>();
      dispose?.call(old);
      sl.unregister<T>();
    }
    sl.registerSingleton<T>(instance);
  }
}
