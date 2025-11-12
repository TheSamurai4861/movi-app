import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';

class TvDataModule {
  static void register() {
    if (sl.isRegistered<TvRepository>()) return;
    sl.registerLazySingleton<TmdbTvRemoteDataSource>(
      () => TmdbTvRemoteDataSource(sl<TmdbClient>()),
    );
    sl.registerLazySingleton<TvLocalDataSource>(
      () => TvLocalDataSource(sl(), sl<LocalePreferences>()),
    );
    sl.registerLazySingleton<TvRepository>(
      () => TvRepositoryImpl(
        sl(),
        sl<TmdbImageResolver>(),
        sl<WatchlistLocalRepository>(),
        sl<TvLocalDataSource>(),
        sl<ContinueWatchingLocalRepository>(),
      ),
    );
  }
}
