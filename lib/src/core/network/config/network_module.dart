// lib/src/core/network/config/network_module.dart
import 'package:dio/dio.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network.dart';

class NetworkModule {
  static const Duration _gracefulSwapDelay = Duration(seconds: 15);

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
    final newExecutor = NetworkExecutor(
      dio,
      logger: logger,
      defaultMaxConcurrent: 12, // Augmenté de 6 à 12 pour éviter les blocages
      limiterAcquireTimeout: const Duration(
        seconds: 10,
      ), // Timeout augmenté pour réduire les échecs
    );
    _swapNetworkStackGracefully(dio: dio, executor: newExecutor);
  }

  static void _swapNetworkStackGracefully({
    required Dio dio,
    required NetworkExecutor executor,
  }) {
    final oldDio = sl.isRegistered<Dio>() ? sl<Dio>() : null;
    final oldExecutor = sl.isRegistered<NetworkExecutor>()
        ? sl<NetworkExecutor>()
        : null;

    if (oldDio != null) {
      sl.unregister<Dio>();
    }
    sl.registerSingleton<Dio>(dio);

    if (oldExecutor != null) {
      sl.unregister<NetworkExecutor>();
    }
    sl.registerSingleton<NetworkExecutor>(executor);

    if (oldExecutor != null) {
      Future<void>.delayed(_gracefulSwapDelay, () {
        oldExecutor.dispose();
      });
    }
    if (oldDio != null) {
      Future<void>.delayed(_gracefulSwapDelay, () {
        oldDio.close(force: true);
      });
    }
  }
}
