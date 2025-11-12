import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/home/data/repositories/home_feed_repository_impl.dart';

class HomeFeedDataModule {
  static void register() {
    if (sl.isRegistered<HomeFeedRepository>()) return;

    sl.registerLazySingleton<HomeFeedRepository>(
      () => HomeFeedRepositoryImpl(
        sl<TmdbMovieRemoteDataSource>(),
        sl<TmdbTvRemoteDataSource>(),
        sl<IptvLocalRepository>(),
        sl<MovieRepository>(),
        sl<TvRepository>(),
        sl<TmdbImageResolver>(),
        sl<AppStateController>(),
        sl<TmdbCacheDataSource>(),
      ),
    );
  }
}
