import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'package:movi/src/features/movie/domain/services/movie_streaming_service.dart';
import 'package:movi/src/features/movie/domain/services/movie_playback_variant_resolver.dart';
import 'package:movi/src/features/movie/domain/services/movie_variant_matcher.dart';
import 'package:movi/src/features/movie/domain/services/iptv_availability_service.dart';
import 'package:movi/src/features/movie/data/services/movie_streaming_service_impl.dart';
import 'package:movi/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart';
import 'package:movi/src/features/movie/data/services/iptv_availability_service_impl.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/movie/domain/usecases/filter_recommendations_by_iptv.dart';
import 'package:movi/src/features/movie/domain/usecases/build_movie_video_source.dart';
import 'package:movi/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart';
import 'package:movi/src/features/movie/domain/usecases/get_movie_availability_on_iptv.dart';
import 'package:movi/src/features/movie/domain/usecases/mark_movie_as_seen.dart';
import 'package:movi/src/features/movie/domain/usecases/mark_movie_as_unseen.dart';
import 'package:movi/src/features/movie/domain/usecases/add_movie_to_playlist.dart';
import 'package:movi/src/features/movie/domain/usecases/ensure_movie_enrichment.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
import 'package:movi/src/shared/domain/services/enrichment_check_service.dart';

class MovieDataModule {
  static void register() {
    if (sl.isRegistered<MovieRepository>()) return;
    sl.registerLazySingleton<TmdbMovieRemoteDataSource>(
      () => TmdbMovieRemoteDataSource(sl<TmdbClient>()),
    );
    sl.registerLazySingleton<MovieLocalDataSource>(
      () => MovieLocalDataSource(sl()),
    );

    // Enregistrer EnrichmentCheckService après que MovieLocalDataSource soit disponible
    // (TvLocalDataSource sera disponible après TvDataModule.register())
    if (!sl.isRegistered<EnrichmentCheckService>() &&
        sl.isRegistered<MovieLocalDataSource>()) {
      // On vérifiera TvLocalDataSource dans TvDataModule
      // Pour l'instant, on attend que TvDataModule soit appelé
    }

    // Enregistrer MovieRepository pour les services qui le consomment via GetIt
    sl.registerLazySingleton<MovieRepository>(
      () => MovieRepositoryImpl(
        sl<TmdbMovieRemoteDataSource>(),
        sl<TmdbImageResolver>(),
        sl<WatchlistLocalRepository>(),
        sl<MovieLocalDataSource>(),
        sl<ContinueWatchingLocalRepository>(),
        sl<AppStateController>(),
      ),
    );

    sl.registerLazySingleton<FilterRecommendationsByIptvAvailability>(
      () => FilterRecommendationsByIptvAvailability(sl<IptvLocalRepository>()),
    );

    if (!sl.isRegistered<XtreamStreamUrlBuilder>()) {
      sl.registerLazySingleton<XtreamStreamUrlBuilder>(
        () => XtreamStreamUrlBuilderImpl(
          iptvLocal: sl<IptvLocalRepository>(),
          vault: sl<CredentialsVault>(),
          networkExecutor: sl<NetworkExecutor>(),
        ),
      );
    }

    if (!sl.isRegistered<PlaybackSelectionService>()) {
      sl.registerLazySingleton<PlaybackSelectionService>(
        () => const PlaybackSelectionService(),
      );
    }

    if (!sl.isRegistered<MovieVariantMatcher>()) {
      sl.registerLazySingleton<MovieVariantMatcher>(
        () => const MovieVariantMatcher(),
      );
    }

    if (!sl.isRegistered<MoviePlaybackVariantResolver>()) {
      sl.registerLazySingleton<MoviePlaybackVariantResolver>(
        () => MoviePlaybackVariantResolverImpl(
          iptvLocal: sl<IptvLocalRepository>(),
          urlBuilder: sl<XtreamStreamUrlBuilder>(),
          matcher: sl<MovieVariantMatcher>(),
          logger: sl<AppLogger>(),
          diagnostics: sl<PerformanceDiagnosticLogger>(),
        ),
      );
    }

    if (!sl.isRegistered<MovieStreamingService>()) {
      sl.registerLazySingleton<MovieStreamingService>(
        () => MovieStreamingServiceImpl(
          iptvLocal: sl<IptvLocalRepository>(),
          vault: sl<CredentialsVault>(),
          logger: sl<AppLogger>(),
          lookup: sl<XtreamLookupService>(),
          networkExecutor: sl<NetworkExecutor>(),
        ),
      );
    }

    if (!sl.isRegistered<IptvAvailabilityService>()) {
      sl.registerLazySingleton<IptvAvailabilityService>(
        () => IptvAvailabilityServiceImpl(
          iptvLocal: sl<IptvLocalRepository>(),
          logger: sl<AppLogger>(),
          lookup: sl<XtreamLookupService>(),
        ),
      );
    }

    if (!sl.isRegistered<BuildMovieVideoSource>()) {
      sl.registerLazySingleton<BuildMovieVideoSource>(
        () => BuildMovieVideoSource(
          sl<MovieStreamingService>(),
          sl<PlaybackHistoryRepository>(),
        ),
      );
    }

    if (!sl.isRegistered<ResolveMoviePlaybackSelection>()) {
      sl.registerLazySingleton<ResolveMoviePlaybackSelection>(
        () => ResolveMoviePlaybackSelection(
          sl<MoviePlaybackVariantResolver>(),
          sl<PlaybackSelectionService>(),
          sl<PlaybackHistoryRepository>(),
          sl<AppLogger>(),
          sl<PerformanceDiagnosticLogger>(),
        ),
      );
    }

    if (!sl.isRegistered<GetMovieAvailabilityOnIptv>()) {
      sl.registerLazySingleton<GetMovieAvailabilityOnIptv>(
        () => GetMovieAvailabilityOnIptv(sl<IptvAvailabilityService>()),
      );
    }

    if (!sl.isRegistered<MarkMovieAsSeen>()) {
      sl.registerLazySingleton<MarkMovieAsSeen>(
        () => MarkMovieAsSeen(sl<PlaybackHistoryRepository>()),
      );
    }

    if (!sl.isRegistered<MarkMovieAsUnseen>()) {
      sl.registerLazySingleton<MarkMovieAsUnseen>(
        () => MarkMovieAsUnseen(
          sl<PlaybackHistoryRepository>(),
          sl<ContinueWatchingRepository>(),
        ),
      );
    }

    if (!sl.isRegistered<AddMovieToPlaylist>()) {
      sl.registerLazySingleton<AddMovieToPlaylist>(
        () => AddMovieToPlaylist(sl<PlaylistRepository>()),
      );
    }

    if (!sl.isRegistered<EnsureMovieEnrichment>()) {
      sl.registerLazySingleton<EnsureMovieEnrichment>(
        () => EnsureMovieEnrichment(
          sl<EnrichmentCheckService>(),
          sl<MovieRepository>(),
          sl<AppStateController>(),
        ),
      );
    }
  }
}
