import '../../../core/di/injector.dart';
import '../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../shared/data/services/tmdb_client.dart';
import 'datasources/tmdb_search_remote_data_source.dart';
import 'search_repository_impl.dart';
import '../domain/repositories/search_repository.dart';

class SearchDataModule {
  static void register() {
    // Repository with pagination support
    if (!sl.isRegistered<TmdbSearchRemoteDataSource>()) {
      sl.registerLazySingleton<TmdbSearchRemoteDataSource>(
        () => TmdbSearchRemoteDataSource(sl<TmdbClient>()),
      );
    }
    if (!sl.isRegistered<SearchRepository>()) {
      sl.registerLazySingleton<SearchRepository>(
        () => SearchRepositoryImpl(
          sl<TmdbSearchRemoteDataSource>(),
          sl<TmdbImageResolver>(),
          sl<IptvLocalRepository>(),
        ),
      );
    }
    // Keep minimal aggregation service for existing UI (delegation can be added later)
  }
}
