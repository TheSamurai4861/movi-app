import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/features/iptv/data/repositories/iptv_repository_impl.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
import 'package:movi/src/features/iptv/application/usecases/list_xtream_playlists.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/secure_credentials_vault.dart';
import 'dart:io' show Platform;
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/services/playlist_mapper.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/logging/logger.dart';

class IptvDataModule {
  static void register() {
    assert(sl.isRegistered<NetworkExecutor>());

    sl.registerLazySingleton<XtreamCacheDataSource>(
      () => XtreamCacheDataSource(
        sl<IptvLocalRepository>(),
        sl<ContentCacheRepository>(),
      ),
    );

    sl.registerLazySingleton<XtreamRemoteDataSource>(
      () => XtreamRemoteDataSource(sl()),
    );
    sl.registerLazySingleton<PlaylistMapper>(() => const PlaylistMapper());

    if (Platform.isWindows) {
      replace<CredentialsVault>(
        CredentialsVaultImpl(sl<ContentCacheRepository>()),
      );
    } else {
      replace<CredentialsVault>(SecureCredentialsVault());
    }

    sl.registerLazySingleton<IptvRepository>(
      () => IptvRepositoryImpl(
        sl<IptvLocalRepository>(),
        sl<CredentialsVault>(),
        sl<XtreamRemoteDataSource>(),
        sl<PlaylistMapper>(),
      ),
    );

    sl.registerLazySingleton<AddXtreamSource>(() => AddXtreamSource(sl()));
    sl.registerLazySingleton<RefreshXtreamCatalog>(
      () => RefreshXtreamCatalog(sl()),
    );
    sl.registerLazySingleton<ListXtreamPlaylists>(
      () => ListXtreamPlaylists(sl()),
    );

    if (!sl.isRegistered<XtreamSyncService>()) {
      sl.registerLazySingleton<XtreamSyncService>(
        () => XtreamSyncService(
          sl<AppStateController>(),
          sl<RefreshXtreamCatalog>(),
          sl<XtreamCacheDataSource>(),
          sl<AppLogger>(),
        ),
      );
    }
  }
}
