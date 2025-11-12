import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/core/storage/storage.dart';

class StorageModule {
  static Future<void> register() async {
    if (!sl.isRegistered<Database>()) {
      final db = await LocalDatabase.instance();
      sl.registerSingleton<Database>(db);
    }

    if (!sl.isRegistered<WatchlistLocalRepository>()) {
      sl.registerLazySingleton<WatchlistLocalRepository>(
        () => const WatchlistLocalRepositoryImpl(),
      );
    }
    if (!sl.isRegistered<ContentCacheRepository>()) {
      sl.registerLazySingleton<ContentCacheRepository>(
        () => ContentCacheRepository(),
      );
    }
    if (!sl.isRegistered<IptvLocalRepository>()) {
      sl.registerLazySingleton<IptvLocalRepository>(
        () => IptvLocalRepository(),
      );
    }
    if (!sl.isRegistered<ContinueWatchingLocalRepository>()) {
      sl.registerLazySingleton<ContinueWatchingLocalRepository>(
        () => const ContinueWatchingLocalRepositoryImpl(),
      );
    }
    if (!sl.isRegistered<HistoryLocalRepository>()) {
      sl.registerLazySingleton<HistoryLocalRepository>(
        () => const HistoryLocalRepositoryImpl(),
      );
    }
  }
}
