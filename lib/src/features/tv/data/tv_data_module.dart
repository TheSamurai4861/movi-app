import '../../../core/di/injector.dart';
import '../../../core/preferences/locale_preferences.dart';
import '../../../shared/data/services/tmdb_client.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../core/storage/repositories/watchlist_local_repository.dart';
import '../../../core/storage/repositories/continue_watching_local_repository.dart';
import '../domain/repositories/tv_repository.dart';
import 'datasources/tmdb_tv_remote_data_source.dart';
import 'datasources/tv_local_data_source.dart';
import 'repositories/tv_repository_impl.dart';

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
