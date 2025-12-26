import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/person/person.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';
import 'package:movi/src/features/library/domain/repositories/history_repository.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
import 'package:movi/src/features/library/domain/services/playlist_backdrop_service.dart';
import 'package:movi/src/features/library/data/repositories/library_repository_impl.dart';
import 'package:movi/src/features/library/data/repositories/favorites_repository_impl.dart';
import 'package:movi/src/features/library/data/repositories/history_repository_impl.dart';
import 'package:movi/src/features/library/data/repositories/playback_history_repository_impl.dart';
import 'package:movi/src/features/library/data/repositories/continue_watching_repository_impl.dart';

class LibraryDataModule {
  static void register() {
    if (sl.isRegistered<LibraryRepository>()) return;
    sl.registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(
        sl<WatchlistLocalRepository>(),
        sl<HistoryLocalRepository>(),
        sl<PlaylistRepository>(),
        sl<PersonRepository>(),
      ),
    );

    if (!sl.isRegistered<FavoritesRepository>()) {
      sl.registerLazySingleton<FavoritesRepository>(
        () => FavoritesRepositoryImpl(sl<WatchlistLocalRepository>()),
      );
    }

    if (!sl.isRegistered<HistoryRepository>()) {
      sl.registerLazySingleton<HistoryRepository>(
        () => HistoryRepositoryImpl(sl<HistoryLocalRepository>()),
      );
    }

    if (!sl.isRegistered<PlaybackHistoryRepository>()) {
      sl.registerLazySingleton<PlaybackHistoryRepository>(
        () => PlaybackHistoryRepositoryImpl(sl<HistoryLocalRepository>()),
      );
    }

    if (!sl.isRegistered<ContinueWatchingRepository>()) {
      sl.registerLazySingleton<ContinueWatchingRepository>(
        () => ContinueWatchingRepositoryImpl(
          sl<ContinueWatchingLocalRepository>(),
        ),
      );
    }

    if (!sl.isRegistered<PlaylistBackdropService>()) {
      sl.registerLazySingleton<PlaylistBackdropService>(
        () => PlaylistBackdropServiceImpl(
          tmdbClient: sl<TmdbClient>(),
          images: sl<TmdbImageResolver>(),
        ),
      );
    }
  }
}
