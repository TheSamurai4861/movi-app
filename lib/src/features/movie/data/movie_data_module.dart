import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

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
        sl<AppStateController>(),
      ),
    );
  }
}
