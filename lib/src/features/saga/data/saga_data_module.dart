import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/domain/usecases/get_saga_detail.dart';
import 'package:movi/src/features/saga/domain/usecases/get_user_sagas.dart';
import 'package:movi/src/features/saga/domain/usecases/search_sagas.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';
import 'package:movi/src/features/saga/data/datasources/saga_local_data_source.dart';
import 'package:movi/src/features/saga/data/repositories/saga_repository_impl.dart';

class SagaDataModule {
  static void register() {
    if (!sl.isRegistered<TmdbSagaRemoteDataSource>()) {
      sl.registerLazySingleton<TmdbSagaRemoteDataSource>(
        () => TmdbSagaRemoteDataSource(sl<TmdbClient>()),
      );
    }

    if (!sl.isRegistered<SagaLocalDataSource>()) {
      sl.registerLazySingleton<SagaLocalDataSource>(
        () => SagaLocalDataSource(
          sl<ContentCacheRepository>(),
          sl<LocalePreferences>(),
        ),
      );
    }

    if (!sl.isRegistered<SagaRepository>()) {
      sl.registerLazySingleton<SagaRepository>(
        () => SagaRepositoryImpl(
          sl<TmdbSagaRemoteDataSource>(),
          sl<TmdbImageResolver>(),
          sl<SagaLocalDataSource>(),
          sl<WatchlistLocalRepository>(),
        ),
      );
    }

    if (!sl.isRegistered<GetSagaDetail>()) {
      sl.registerLazySingleton<GetSagaDetail>(
        () => GetSagaDetail(sl<SagaRepository>()),
      );
    }
    if (!sl.isRegistered<GetUserSagas>()) {
      sl.registerLazySingleton<GetUserSagas>(
        () => GetUserSagas(sl<SagaRepository>()),
      );
    }
    if (!sl.isRegistered<SearchSagas>()) {
      sl.registerLazySingleton<SearchSagas>(
        () => SearchSagas(sl<SagaRepository>()),
      );
    }
  }
}
