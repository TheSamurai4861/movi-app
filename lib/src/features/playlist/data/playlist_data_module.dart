import '../../../core/di/injector.dart';
import '../../../core/storage/repositories/playlist_local_repository.dart';
import '../domain/repositories/playlist_repository.dart';
import 'repositories/playlist_repository_impl.dart';

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
