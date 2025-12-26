import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/playlist/data/repositories/playlist_repository_impl.dart';

class PlaylistDataModule {
  static void register() {
    if (!sl.isRegistered<PlaylistLocalRepository>()) {
      sl.registerLazySingleton<PlaylistLocalRepository>(
        () => PlaylistLocalRepository(
          db: sl<Database>(),
          outbox: sl<SyncOutboxRepository>(),
        ),
      );
    }
    if (!sl.isRegistered<PlaylistRepository>()) {
      sl.registerLazySingleton<PlaylistRepository>(
        () => PlaylistRepositoryImpl(sl<PlaylistLocalRepository>()),
      );
    }
  }
}
