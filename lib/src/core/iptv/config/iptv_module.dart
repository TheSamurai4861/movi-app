import '../../di/injector.dart';
import '../../network/network_executor.dart';
import '../application/services/playlist_mapper.dart';
import '../application/usecases/add_xtream_source.dart';
import '../application/usecases/list_xtream_playlists.dart';
import '../application/usecases/refresh_xtream_catalog.dart';
import '../data/datasources/xtream_cache_data_source.dart';
import '../data/datasources/xtream_remote_data_source.dart';
import '../data/repositories/iptv_repository_impl.dart';
import '../domain/repositories/iptv_repository.dart';
import '../../storage/repositories/iptv_local_repository.dart';
import '../../storage/repositories/content_cache_repository.dart';
import '../application/services/xtream_sync_service.dart';
import '../../state/app_state_controller.dart';
import '../../utils/logger.dart';

class IptvModule {
  static void register() {
    if (sl.isRegistered<IptvRepository>()) return;
    if (!sl.isRegistered<NetworkExecutor>()) {
      throw StateError('NetworkExecutor must be registered before IptvModule.');
    }

    sl.registerLazySingleton<XtreamCacheDataSource>(
      () => XtreamCacheDataSource(sl<IptvLocalRepository>(), sl<ContentCacheRepository>()),
    );
    sl.registerLazySingleton<XtreamRemoteDataSource>(() => XtreamRemoteDataSource(sl()));
    sl.registerLazySingleton<PlaylistMapper>(() => const PlaylistMapper());

    sl.registerLazySingleton<IptvRepository>(
      () => IptvRepositoryImpl(sl(), sl(), sl()),
    );

    sl.registerLazySingleton<AddXtreamSource>(() => AddXtreamSource(sl()));
    sl.registerLazySingleton<RefreshXtreamCatalog>(() => RefreshXtreamCatalog(sl()));
    sl.registerLazySingleton<ListXtreamPlaylists>(() => ListXtreamPlaylists(sl()));

    // Background sync service (not auto-started)
    if (!sl.isRegistered<XtreamSyncService>()) {
      sl.registerLazySingleton<XtreamSyncService>(
        () => XtreamSyncService(
          sl<AppStateController>(),
          sl<RefreshXtreamCatalog>(),
          sl<XtreamCacheDataSource>(),
          logger: sl<AppLogger>(),
        ),
      );
    }
  }
}
