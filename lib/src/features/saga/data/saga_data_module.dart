import '../../../core/di/injector.dart';
import '../../../shared/data/services/tmdb_client.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../domain/repositories/saga_repository.dart';
import 'datasources/tmdb_saga_remote_data_source.dart';
import 'datasources/saga_local_data_source.dart';
import 'repositories/saga_repository_impl.dart';
import '../../../core/storage/repositories/watchlist_local_repository.dart';

class SagaDataModule {
  static void register() {
    if (sl.isRegistered<SagaRepository>()) return;
    sl.registerLazySingleton<TmdbSagaRemoteDataSource>(
      () => TmdbSagaRemoteDataSource(sl<TmdbClient>()),
    );
    sl.registerLazySingleton<SagaLocalDataSource>(
      () => SagaLocalDataSource(sl(), sl()),
    );
    sl.registerLazySingleton<SagaRepository>(
      () => SagaRepositoryImpl(
        sl(),
        sl<TmdbImageResolver>(),
        sl<SagaLocalDataSource>(),
        sl<WatchlistLocalRepository>(),
      ),
    );
  }
}
