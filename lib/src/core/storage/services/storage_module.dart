import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/secure_credentials_vault.dart';
import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/core/storage/storage.dart';

/// Registers all storage-layer dependencies.
///
/// In tests, prefer overriding repositories with in-memory fakes before calling
/// [register] to avoid touching the on-disk SQLite database.
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
    if (!sl.isRegistered<PlaylistLocalRepository>()) {
      sl.registerLazySingleton<PlaylistLocalRepository>(
        () => PlaylistLocalRepository(),
      );
    }
    if (!sl.isRegistered<SecureStorageRepository>()) {
      sl.registerLazySingleton<SecureStorageRepository>(
        () => SecureStorageRepository(),
      );
    }
    if (!sl.isRegistered<CredentialsVault>()) {
      sl.registerLazySingleton<CredentialsVault>(
        () => SecureCredentialsVault(),
      );
    }
  }

  static Future<void> dispose() async {
    await LocalDatabase.dispose();
    if (sl.isRegistered<Database>()) {
      sl.unregister<Database>();
    }
  }
}
