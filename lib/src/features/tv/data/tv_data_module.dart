import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/preferences/preferences.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';
import 'package:movi/src/features/tv/data/services/episode_playback_variant_resolver_impl.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/tv/domain/services/episode_playback_variant_resolver.dart';
import 'package:movi/src/features/tv/domain/usecases/ensure_tv_enrichment.dart';
import 'package:movi/src/features/tv/domain/usecases/mark_series_as_seen.dart';
import 'package:movi/src/features/tv/domain/usecases/mark_series_as_unseen.dart';
import 'package:movi/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart';
import 'package:movi/src/features/tv/domain/usecases/resolve_series_playback_target.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_detail_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/services/enrichment_check_service.dart';

class TvDataModule {
  static void register() {
    _registerDataSources();
    _registerRepositories();
    _registerEnrichmentDependencies();
    _registerPlaybackDependencies();
    _registerUseCases();
  }

  static void _registerDataSources() {
    if (!sl.isRegistered<TmdbTvRemoteDataSource>()) {
      sl.registerLazySingleton<TmdbTvRemoteDataSource>(
        () => TmdbTvRemoteDataSource(sl<TmdbClient>()),
      );
    }

    if (!sl.isRegistered<TvLocalDataSource>()) {
      sl.registerLazySingleton<TvLocalDataSource>(
        () => TvLocalDataSource(
          sl<ContentCacheRepository>(),
          sl<LocalePreferences>(),
        ),
      );
    }
  }

  static void _registerRepositories() {
    if (!sl.isRegistered<TvRepository>()) {
      sl.registerLazySingleton<TvRepository>(
        () => TvRepositoryImpl(
          sl<TmdbTvRemoteDataSource>(),
          sl<TmdbImageResolver>(),
          sl<WatchlistLocalRepository>(),
          sl<TvLocalDataSource>(),
          sl<ContinueWatchingLocalRepository>(),
          sl<AppStateController>(),
          sl<TmdbCacheDataSource>(),
          detailCache: sl<TmdbDetailCacheDataSource>(),
        ),
      );
    }
  }

  static void _registerEnrichmentDependencies() {
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
  }

  static void _registerPlaybackDependencies() {
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
        () => PlaybackSelectionService(),
      );
    }

    if (!sl.isRegistered<EpisodePlaybackVariantResolver>()) {
      sl.registerLazySingleton<EpisodePlaybackVariantResolver>(
        () => EpisodePlaybackVariantResolverImpl(
          iptvLocal: sl<IptvLocalRepository>(),
          urlBuilder: sl<XtreamStreamUrlBuilder>(),
          logger: sl<AppLogger>(),
          diagnostics: sl<PerformanceDiagnosticLogger>(),
        ),
      );
    }
  }

  static void _registerUseCases() {
    if (!sl.isRegistered<EnsureTvEnrichment>()) {
      sl.registerLazySingleton<EnsureTvEnrichment>(
        () => EnsureTvEnrichment(
          sl<EnrichmentCheckService>(),
          sl<TvRepository>(),
          sl<AppStateController>(),
        ),
      );
    }

    if (!sl.isRegistered<ResolveEpisodePlaybackSelection>()) {
      sl.registerLazySingleton<ResolveEpisodePlaybackSelection>(
        () => ResolveEpisodePlaybackSelection(
          sl<EpisodePlaybackVariantResolver>(),
          sl<PlaybackSelectionService>(),
          sl<PlaybackHistoryRepository>(),
          sl<AppLogger>(),
          sl<PerformanceDiagnosticLogger>(),
        ),
      );
    }

    if (!sl.isRegistered<ResolveSeriesPlaybackTarget>()) {
      sl.registerLazySingleton<ResolveSeriesPlaybackTarget>(
        () => const ResolveSeriesPlaybackTarget(),
      );
    }

    if (!sl.isRegistered<MarkSeriesAsSeen>()) {
      sl.registerLazySingleton<MarkSeriesAsSeen>(
        () => MarkSeriesAsSeen(
          sl<SeriesSeenStateRepository>(),
          sl<ContinueWatchingRepository>(),
          sl<AppLogger>(),
        ),
      );
    }

    if (!sl.isRegistered<MarkSeriesAsUnseen>()) {
      sl.registerLazySingleton<MarkSeriesAsUnseen>(
        () => MarkSeriesAsUnseen(
          sl<PlaybackHistoryRepository>(),
          sl<ContinueWatchingRepository>(),
          sl<SeriesSeenStateRepository>(),
        ),
      );
    }
  }
}
