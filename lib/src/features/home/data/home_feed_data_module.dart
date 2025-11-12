import '../../../core/di/injector.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../shared/data/services/tmdb_cache_data_source.dart';
import '../../movie/data/datasources/tmdb_movie_remote_data_source.dart';
import '../../movie/domain/repositories/movie_repository.dart';
import '../../tv/data/datasources/tmdb_tv_remote_data_source.dart';
import '../../tv/domain/repositories/tv_repository.dart';
import '../domain/repositories/home_feed_repository.dart';
import 'repositories/home_feed_repository_impl.dart';

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
