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
    if (!sl.isRegistered<AppConfig>()) {
      throw StateError('AppConfig must be registered before NetworkModule.');
    }

    _ensureTmdbCacheDataSource();

    final config = sl<AppConfig>();
    final logger = sl<AppLogger>();
    final secretStore = sl<SecretStore>();

    final factory = HttpClientFactory(
      config: config,
      logger: logger,
      localeProvider: localeProvider,
      authTokenProvider: _buildTmdbTokenProvider(
        config.network,
        secretStore,
      ),
    );

    final dio = factory.create();
    _replaceSingleton<Dio>(dio, (old) => old.close(force: true));
    _replaceSingleton<NetworkExecutor>(
      NetworkExecutor(dio, logger: logger),
      (old) => old.dispose(),
    );
  }

  static void _ensureTmdbCacheDataSource() {
    if (!sl.isRegistered<TmdbCacheDataSource>()) {
      sl.registerLazySingleton<TmdbCacheDataSource>(
        () => TmdbCacheDataSource(sl<ContentCacheRepository>()),
      );
    }
  }

  static AuthTokenProvider? _buildTmdbTokenProvider(
    NetworkEndpoints endpoints,
    SecretStore secretStore,
  ) {
    final host = endpoints.resolvedTmdbBaseHost.toLowerCase();

    return MemoizedTokenProvider(
      loader: () async {
        final configured = endpoints.tmdbApiKey?.trim();
        if (configured != null && configured.isNotEmpty) {
          if (_isV3Key(configured)) return null;
          return configured;
        }
        final secret = await secretStore.read('TMDB_API_KEY');
        if (secret == null || secret.isEmpty) return null;
        if (_isV3Key(secret)) return null;
        return secret;
      },
      appliesTo: (request) => request.uri.host.toLowerCase() == host,
    );
  }

  static bool _isV3Key(String key) =>
      !key.startsWith('eyJ') && key.length <= 64;

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
