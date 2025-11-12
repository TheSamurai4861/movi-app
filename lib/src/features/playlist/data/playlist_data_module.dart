import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/playlist/data/repositories/playlist_repository_impl.dart';

class PlaylistDataModule {
  static void register() {
    if (sl.isRegistered<PlaylistRepository>()) return;
    sl.registerLazySingleton<PlaylistLocalRepository>(
      () => PlaylistLocalRepository(),
    );
    sl.registerLazySingleton<PlaylistRepository>(
      () => PlaylistRepositoryImpl(sl<PlaylistLocalRepository>()),
    );
  }
}
