import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/home/domain/repositories/home_feed_repository.dart';
import 'package:movi/src/features/home/domain/services/movie_playback_service.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/features/home/domain/services/home_hero_metadata_service.dart';
import 'package:movi/src/features/home/domain/services/continue_watching_enrichment_service.dart';
import 'package:movi/src/features/home/domain/usecases/load_continue_watching_media.dart';
import 'package:movi/src/features/home/data/repositories/home_feed_repository_impl.dart';

class HomeFeedDataModule {
  static void register() {
    if (sl.isRegistered<HomeFeedRepository>()) return;

    sl.registerLazySingleton<HomeFeedRepository>(
      () => HomeFeedRepositoryImpl(
        sl<TmdbMovieRemoteDataSource>(),
        sl<TmdbTvRemoteDataSource>(),
        sl<IptvCatalogReader>(),
        sl<MovieRepository>(),
        sl<TvRepository>(),
        sl<TmdbImageResolver>(),
        sl<AppStateController>(),
        sl<TmdbCacheDataSource>(),
      ),
    );

    // Enregistrer le service de lookup Xtream
    if (!sl.isRegistered<XtreamLookupService>()) {
      sl.registerLazySingleton<XtreamLookupService>(
        () => XtreamLookupService(
          iptvLocal: sl<IptvLocalRepository>(),
          logger: sl<AppLogger>(),
        ),
      );
    }

    // Enregistrer le service de playback
    if (!sl.isRegistered<MoviePlaybackService>()) {
      sl.registerLazySingleton<MoviePlaybackService>(
        () => MoviePlaybackService(
          iptvLocal: sl<IptvLocalRepository>(),
          vault: sl<CredentialsVault>(),
          logger: sl<AppLogger>(),
          lookup: sl<XtreamLookupService>(),
        ),
      );
    }

    // Enregistrer le service de métadonnées du hero
    if (!sl.isRegistered<HomeHeroMetadataService>()) {
      sl.registerLazySingleton<HomeHeroMetadataService>(
        () => HomeHeroMetadataService(
          cache: sl<TmdbCacheDataSource>(),
          images: sl<TmdbImageResolver>(),
          moviesRemote: sl<TmdbMovieRemoteDataSource>(),
          tvRemote: sl<TmdbTvRemoteDataSource>(),
          appState: sl<AppStateController>(),
        ),
      );
    }

    // Service d'enrichissement "Continue Watching" (historique + TMDB)
    if (!sl.isRegistered<ContinueWatchingEnrichmentService>()) {
      sl.registerLazySingleton<ContinueWatchingEnrichmentService>(
        () => ContinueWatchingEnrichmentService(
          historyRepo: sl<HistoryLocalRepository>(),
          movieRepository: sl<MovieRepository>(),
          tvRepository: sl<TvRepository>(),
          tmdbClient: sl<TmdbClient>(),
          images: sl<TmdbImageResolver>(),
        ),
      );
    }

    // Use case LoadContinueWatchingMedia
    if (!sl.isRegistered<LoadContinueWatchingMedia>()) {
      sl.registerLazySingleton<LoadContinueWatchingMedia>(
        () =>
            LoadContinueWatchingMedia(sl<ContinueWatchingEnrichmentService>()),
      );
    }
  }
}
