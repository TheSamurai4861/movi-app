import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/secure_credentials_vault.dart';
import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/core/storage/database/sqlite_database_maintenance.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/services/xtream_lookup.dart';

/// Registers all storage-layer dependencies.
///
/// In tests, prefer overriding repositories with in-memory fakes before calling
/// [register] to avoid touching the on-disk SQLite database.
class StorageModule {
  static const int _databaseVersion = 19;

  static Future<void> register({bool? allowInMemoryFallback}) async {
    final stopwatch = Stopwatch()..start();
    _logDebug('StorageModule.register: START');

    try {
      await _registerPersistentDatabase(stopwatch: stopwatch);
      _registerRepositories();
      _logDebug(
        'StorageModule.register: COMPLETE '
        '(total: ${stopwatch.elapsedMilliseconds}ms)',
      );
    } catch (error, stackTrace) {
      _logError(
        'StorageModule.register: failed to initialize persistent storage',
        error,
        stackTrace,
      );

      final isFallbackAllowed = _resolveAllowInMemoryFallback(
        allowInMemoryFallback,
      );
      if (!isFallbackAllowed) {
        final exception = StateError(
          'Storage initialization failed and in-memory fallback is disabled. '
          'Original error: $error',
        );
        Error.throwWithStackTrace(exception, stackTrace);
      }

      await _registerInMemoryFallback(
        stopwatch: stopwatch,
        originalError: error,
      );
    }
  }

  static bool _resolveAllowInMemoryFallback(bool? explicitOverride) {
    if (explicitOverride != null) {
      return explicitOverride;
    }
    if (!sl.isRegistered<AppConfig>()) {
      return false;
    }
    return sl<AppConfig>().featureFlags.allowInMemoryStorageFallback;
  }

  static Future<void> _registerPersistentDatabase({
    required Stopwatch stopwatch,
  }) async {
    if (sl.isRegistered<Database>()) {
      return;
    }

    _logDebug('StorageModule.register: initializing LocalDatabase');
    final database = await LocalDatabase.instance().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException(
          'LocalDatabase.instance timeout',
          const Duration(seconds: 10),
        );
      },
    );

    sl.registerSingleton<Database>(database);
    _logDebug(
      'StorageModule.register: LocalDatabase registered '
      '(${stopwatch.elapsedMilliseconds}ms)',
    );
  }

  static Future<void> _registerInMemoryFallback({
    required Stopwatch stopwatch,
    required Object originalError,
  }) async {
    _logWarning(
      'StorageModule.register: using in-memory fallback because '
      'featureFlags.allowInMemoryStorageFallback is enabled. '
      'Original error: $originalError',
    );

    if (!sl.isRegistered<Database>()) {
      final database = await _createInMemoryDatabase();
      sl.registerSingleton<Database>(database);
      _logWarning('StorageModule.register: in-memory database registered');
    }

    _registerRepositories();
    _logWarning(
      'StorageModule.register: COMPLETE in degraded mode '
      '(total: ${stopwatch.elapsedMilliseconds}ms)',
    );
  }

  static Future<Database> _createInMemoryDatabase() {
    return openDatabase(
      inMemoryDatabasePath,
      version: _databaseVersion,
      onConfigure: (db) async {
        await LocalDatabaseMaintenance.onConfigure(db);
      },
      onOpen: (db) async {
        await LocalDatabaseMaintenance.onOpen(db);
      },
      onCreate: (db, version) async {
        await LocalDatabaseSchema.create(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await LocalDatabaseMigrations.upgrade(db, oldVersion, newVersion);
      },
    );
  }

  static void _registerRepositories() {
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

    if (!sl.isRegistered<SyncOutboxRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<SyncOutboxRepository>(
        () => SyncOutboxRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<ContentCacheRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<ContentCacheRepository>(
        () => ContentCacheRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<WatchlistLocalRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<WatchlistLocalRepository>(
        () => WatchlistLocalRepositoryImpl(
          db: sl<Database>(),
          outbox: sl.isRegistered<SyncOutboxRepository>()
              ? sl<SyncOutboxRepository>()
              : null,
        ),
      );
    }

    if (!sl.isRegistered<HistoryLocalRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<HistoryLocalRepository>(
        () => HistoryLocalRepositoryImpl(sl<Database>()),
      );
    }

    if (!sl.isRegistered<ContinueWatchingLocalRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<ContinueWatchingLocalRepository>(
        () => ContinueWatchingLocalRepositoryImpl(sl<Database>()),
      );
    }

    if (!sl.isRegistered<PlaylistLocalRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<PlaylistLocalRepository>(
        () => PlaylistLocalRepository(
          db: sl<Database>(),
          outbox: sl.isRegistered<SyncOutboxRepository>()
              ? sl<SyncOutboxRepository>()
              : null,
        ),
      );
    }

    if (!sl.isRegistered<IptvLocalRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<IptvLocalRepository>(
        () => IptvLocalRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<PlaybackVariantSelectionLocalRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<PlaybackVariantSelectionLocalRepository>(
        () => PlaybackVariantSelectionLocalRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<XtreamLookupService>() &&
        sl.isRegistered<IptvLocalRepository>() &&
        sl.isRegistered<AppLogger>()) {
      sl.registerLazySingleton<XtreamLookupService>(
        () => XtreamLookupService(
          iptvLocal: sl<IptvLocalRepository>(),
          logger: sl<AppLogger>(),
        ),
      );
    }

    if (!sl.isRegistered<XtreamLookup>() &&
        sl.isRegistered<XtreamLookupService>()) {
      sl.registerLazySingleton<XtreamLookup>(() => sl<XtreamLookupService>());
    }
  }

  static void _logDebug(String message) {
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().debug(message, category: 'storage');
      return;
    }
    debugPrint('[StorageModule][DEBUG] $message');
  }

  static void _logWarning(String message) {
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().warn(message, category: 'storage');
      return;
    }
    debugPrint('[StorageModule][WARN] $message');
  }

  static void _logError(String message, Object error, StackTrace stackTrace) {
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().log(
        LogLevel.error,
        message,
        category: 'storage',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    debugPrint('[StorageModule][ERROR] $message');
    debugPrint('[StorageModule][ERROR] $error');
    debugPrint('[StorageModule][ERROR] $stackTrace');
  }
}
