import '../../../core/di/injector.dart';
import '../../../core/preferences/locale_preferences.dart';
import '../../../core/storage/repositories/content_cache_repository.dart';
import '../../../shared/data/services/tmdb_client.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../domain/repositories/person_repository.dart';
import 'datasources/tmdb_person_remote_data_source.dart';
import 'datasources/person_local_data_source.dart';
import 'repositories/person_repository_impl.dart';

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
      ),
    );
  }
}
