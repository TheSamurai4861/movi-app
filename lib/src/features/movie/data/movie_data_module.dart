import '../../../core/di/injector.dart';
import '../../../shared/data/services/tmdb_client.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../core/storage/repositories/watchlist_local_repository.dart';
import '../../../core/storage/repositories/continue_watching_local_repository.dart';
import '../domain/repositories/movie_repository.dart';
import 'datasources/tmdb_movie_remote_data_source.dart';
import 'datasources/movie_local_data_source.dart';
import 'repositories/movie_repository_impl.dart';

class MovieDataModule {
  static void register() {
    if (sl.isRegistered<MovieRepository>()) return;
    sl.registerLazySingleton<TmdbMovieRemoteDataSource>(
      () => TmdbMovieRemoteDataSource(sl<TmdbClient>()),
    );
    sl.registerLazySingleton<MovieLocalDataSource>(
      () => MovieLocalDataSource(sl()),
    );
    sl.registerLazySingleton<MovieRepository>(
      () => MovieRepositoryImpl(
        sl(),
        sl<TmdbImageResolver>(),
        sl<WatchlistLocalRepository>(),
        sl<MovieLocalDataSource>(),
        sl<ContinueWatchingLocalRepository>(),
      ),
    );
  }
}
