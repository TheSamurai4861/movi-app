import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';
import 'package:movi/src/features/saga/data/repositories/saga_repository_impl.dart';
import 'package:movi/src/core/storage/storage.dart';

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
