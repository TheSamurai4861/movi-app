import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/person/data/datasources/tmdb_person_remote_data_source.dart';
import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
import 'package:movi/src/features/person/data/repositories/person_repository_impl.dart';

class PersonDataModule {
  static void register() {
    if (sl.isRegistered<PersonRepository>()) return;
    sl.registerLazySingleton<TmdbPersonRemoteDataSource>(
      () => TmdbPersonRemoteDataSource(sl<TmdbClient>()),
    );
    sl.registerLazySingleton<PersonLocalDataSource>(
      () => PersonLocalDataSource(
        sl<ContentCacheRepository>(),
        sl<LocalePreferences>(),
      ),
    );
    sl.registerLazySingleton<PersonRepository>(
      () => PersonRepositoryImpl(
        sl(),
        sl<TmdbImageResolver>(),
        sl<PersonLocalDataSource>(),
        sl<LocalePreferences>(),
      ),
    );
  }
}
