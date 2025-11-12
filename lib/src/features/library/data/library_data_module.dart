import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/data/repositories/library_repository_impl.dart';

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
