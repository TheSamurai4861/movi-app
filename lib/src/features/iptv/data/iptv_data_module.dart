import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/features/iptv/data/datasources/stalker_remote_data_source.dart';
import 'package:movi/src/features/iptv/data/datasources/stalker_cache_data_source.dart';
import 'package:movi/src/features/iptv/data/repositories/iptv_repository_impl.dart';
import 'package:movi/src/features/iptv/data/repositories/stalker_repository_impl.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/repositories/stalker_repository.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
import 'package:movi/src/features/iptv/application/usecases/add_stalker_source.dart';
import 'package:movi/src/features/iptv/application/usecases/list_xtream_playlists.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/core/performance/domain/performance_tuning.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/services/playlist_mapper.dart';
import 'package:movi/src/features/iptv/data/mappers/stalker_playlist_mapper.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';

class IptvDataModule {
  static void register() {
    assert(sl.isRegistered<NetworkExecutor>());

    if (!sl.isRegistered<XtreamCacheDataSource>()) {
      sl.registerLazySingleton<XtreamCacheDataSource>(
        () => XtreamCacheDataSource(sl<ContentCacheRepository>()),
      );
    }

    if (!sl.isRegistered<XtreamRemoteDataSource>()) {
      sl.registerLazySingleton<XtreamRemoteDataSource>(
        () => XtreamRemoteDataSource(sl()),
      );
    }
    if (!sl.isRegistered<PlaylistMapper>()) {
      sl.registerLazySingleton<PlaylistMapper>(() => const PlaylistMapper());
    }

    if (!sl.isRegistered<IptvRepository>()) {
      sl.registerLazySingleton<IptvRepository>(
        () => IptvRepositoryImpl(
          sl<IptvLocalRepository>(),
          sl<CredentialsVault>(),
          sl<XtreamRemoteDataSource>(),
          sl<PlaylistMapper>(),
          sl<XtreamCacheDataSource>(),
          sl<AppLogger>(),
          sl<PerformanceTuning>(),
        ),
      );
    }

    if (!sl.isRegistered<IptvCatalogReader>()) {
      sl.registerLazySingleton<IptvCatalogReader>(
        () => IptvCatalogReader(sl<IptvLocalRepository>()),
      );
    }

    if (!sl.isRegistered<AddXtreamSource>()) {
      sl.registerLazySingleton<AddXtreamSource>(() => AddXtreamSource(sl()));
    }

    // Stalker dependencies
    if (!sl.isRegistered<StalkerCacheDataSource>()) {
      sl.registerLazySingleton<StalkerCacheDataSource>(
        () => StalkerCacheDataSource(sl<ContentCacheRepository>()),
      );
    }

    if (!sl.isRegistered<StalkerRemoteDataSource>()) {
      sl.registerLazySingleton<StalkerRemoteDataSource>(
        () => StalkerRemoteDataSource(sl<NetworkExecutor>()),
      );
    }

    if (!sl.isRegistered<StalkerPlaylistMapper>()) {
      sl.registerLazySingleton<StalkerPlaylistMapper>(
        () => const StalkerPlaylistMapper(),
      );
    }

    if (!sl.isRegistered<StalkerRepository>()) {
      sl.registerLazySingleton<StalkerRepository>(
        () => StalkerRepositoryImpl(
          sl<IptvLocalRepository>(),
          sl<CredentialsVault>(),
          sl<StalkerRemoteDataSource>(),
          sl<StalkerPlaylistMapper>(),
          sl<StalkerCacheDataSource>(),
          sl<AppLogger>(),
          sl<PerformanceTuning>(),
        ),
      );
    }

    if (!sl.isRegistered<AddStalkerSource>()) {
      sl.registerLazySingleton<AddStalkerSource>(
        () => AddStalkerSource(sl<StalkerRepository>()),
      );
    }

    if (!sl.isRegistered<RefreshXtreamCatalog>()) {
      sl.registerLazySingleton<RefreshXtreamCatalog>(
        () => RefreshXtreamCatalog(sl()),
      );
    }

    if (!sl.isRegistered<RefreshStalkerCatalog>()) {
      sl.registerLazySingleton<RefreshStalkerCatalog>(
        () => RefreshStalkerCatalog(sl()),
      );
    }

    if (!sl.isRegistered<ListXtreamPlaylists>()) {
      sl.registerLazySingleton<ListXtreamPlaylists>(
        () => ListXtreamPlaylists(sl()),
      );
    }

    if (!sl.isRegistered<XtreamSyncService>()) {
      sl.registerLazySingleton<XtreamSyncService>(
        () => XtreamSyncService(
          sl<AppStateController>(),
          sl<RefreshXtreamCatalog>(),
          sl<XtreamCacheDataSource>(),
          sl<AppLogger>(),
          interval: sl<IptvSyncPreferences>().syncInterval,
          initialTickDelay: sl<PerformanceTuning>().iptvInitialSyncDelay,
        ),
      );
    }
  }
}
