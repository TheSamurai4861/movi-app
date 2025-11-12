import 'package:sqflite/sqflite.dart';

import '../../../core/di/injector.dart';
import '../database/sqlite_database.dart';
import '../repositories/watchlist_local_repository.dart';
import '../repositories/content_cache_repository.dart';
import '../repositories/iptv_local_repository.dart';
import '../repositories/continue_watching_local_repository.dart';
import '../repositories/history_local_repository.dart';

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
