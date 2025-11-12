import '../../../core/di/injector.dart';
import '../../../core/storage/repositories/iptv_local_repository.dart';
import '../../../shared/data/services/tmdb_image_resolver.dart';
import '../../../shared/data/services/tmdb_client.dart';
import '../../../shared/domain/services/similarity_service.dart';
import '../../../shared/data/services/similarity/hybrid_similarity_service.dart';
import 'datasources/tmdb_search_remote_data_source.dart';
import 'datasources/search_history_local_data_source.dart';
import 'search_repository_impl.dart';
import '../domain/repositories/search_repository.dart';
import '../domain/repositories/search_history_repository.dart';
import 'repositories/search_history_repository_impl.dart';

class SearchDataModule {
  static void register() {
    // Similarity service registration
    if (!sl.isRegistered<SimilarityService>()) {
      sl.registerLazySingleton<SimilarityService>(
        () => const HybridSimilarityService(),
      );
    }
    // Repository with pagination support
    if (!sl.isRegistered<TmdbSearchRemoteDataSource>()) {
      sl.registerLazySingleton<TmdbSearchRemoteDataSource>(
        () => TmdbSearchRemoteDataSource(sl<TmdbClient>(), sl()),
      );
    }
    if (!sl.isRegistered<SearchRepository>()) {
      sl.registerLazySingleton<SearchRepository>(
        () => SearchRepositoryImpl(
          sl<TmdbSearchRemoteDataSource>(),
          sl<TmdbImageResolver>(),
          sl<IptvLocalRepository>(),
          sl<SimilarityService>(),
        ),
      );
    }
    // Search history local
    if (!sl.isRegistered<SearchHistoryLocalDataSource>()) {
      sl.registerLazySingleton<SearchHistoryLocalDataSource>(
        () => SearchHistoryLocalDataSource(sl()),
      );
    }
    if (!sl.isRegistered<SearchHistoryRepository>()) {
      sl.registerLazySingleton<SearchHistoryRepository>(
        () => SearchHistoryRepositoryImpl(sl<SearchHistoryLocalDataSource>()),
      );
    }
    // Keep minimal aggregation service for existing UI (delegation can be added later)
  }
}
