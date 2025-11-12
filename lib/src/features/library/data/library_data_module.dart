import '../../../core/di/injector.dart';
import '../../../core/storage/repositories/watchlist_local_repository.dart';
import '../../../core/storage/repositories/history_local_repository.dart';
import '../../playlist/domain/repositories/playlist_repository.dart';
import '../domain/repositories/library_repository.dart';
import 'repositories/library_repository_impl.dart';

class LibraryDataModule {
  static void register() {
    if (sl.isRegistered<LibraryRepository>()) return;
    sl.registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(
        sl<WatchlistLocalRepository>(),
        sl<HistoryLocalRepository>(),
        sl<PlaylistRepository>(),
      ),
    );
  }
}
