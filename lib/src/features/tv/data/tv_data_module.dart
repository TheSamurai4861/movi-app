import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/usecases/ensure_tv_enrichment.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/shared/domain/services/enrichment_check_service.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';

class TvDataModule {
  static void register() {
    if (sl.isRegistered<TvRepository>()) return;
    sl.registerLazySingleton<TmdbTvRemoteDataSource>(
      () => TmdbTvRemoteDataSource(sl<TmdbClient>()),
    );
    sl.registerLazySingleton<TvLocalDataSource>(
      () => TvLocalDataSource(sl(), sl<LocalePreferences>()),
    );

    // Enregistrer EnrichmentCheckService maintenant que MovieLocalDataSource
    // et TvLocalDataSource sont disponibles
    if (!sl.isRegistered<EnrichmentCheckService>() &&
        sl.isRegistered<MovieLocalDataSource>() &&
        sl.isRegistered<TvLocalDataSource>()) {
      sl.registerLazySingleton<EnrichmentCheckService>(
        () => EnrichmentCheckServiceImpl(
          sl<MovieLocalDataSource>(),
          sl<TvLocalDataSource>(),
        ),
      );
    }

    sl.registerLazySingleton<TvRepository>(
      () => TvRepositoryImpl(
        sl(),
        sl<TmdbImageResolver>(),
        sl<WatchlistLocalRepository>(),
        sl<TvLocalDataSource>(),
        sl<ContinueWatchingLocalRepository>(),
        sl<AppStateController>(),
      ),
    );

    if (!sl.isRegistered<EnsureTvEnrichment>()) {
      sl.registerLazySingleton<EnsureTvEnrichment>(
        () => EnsureTvEnrichment(
          sl<EnrichmentCheckService>(),
          sl<TvRepository>(),
          sl<AppStateController>(),
        ),
      );
    }
  }
}
