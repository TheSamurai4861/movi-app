import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/secure_credentials_vault.dart';
import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/core/storage/database/sqlite_database_maintenance.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart'
    as content_cache_repo;
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/services/xtream_lookup.dart';

/// Registers all storage-layer dependencies.
///
/// In tests, prefer overriding repositories with in-memory fakes before calling
/// [register] to avoid touching the on-disk SQLite database.
class StorageModule {
  static const int _databaseVersion = 24;

  static Future<void> register({bool? allowInMemoryFallback}) async {
    final stopwatch = Stopwatch()..start();
    _logDebug('register start');

    try {
      await _registerPersistentDatabase(stopwatch: stopwatch);
      _registerRepositories();
      _logDebug(
        'register complete durationMs=${stopwatch.elapsedMilliseconds}',
      );
    } catch (error, stackTrace) {
      _logError(
        action: 'register',
        code: 'storage_init_failed',
        context: 'stage=persistent_storage',
        error: error,
        stackTrace: stackTrace,
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

    _logDebug('register_persistent_database start');
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
      'register_persistent_database success durationMs=${stopwatch.elapsedMilliseconds}',
    );
  }

  static Future<void> _registerInMemoryFallback({
    required Stopwatch stopwatch,
    required Object originalError,
  }) async {
    _logWarning(
      action: 'register',
      result: 'degraded',
      code: 'storage_in_memory_fallback_enabled',
      context: 'reason=feature_flag errorType=${originalError.runtimeType}',
    );

    if (!sl.isRegistered<Database>()) {
      final database = await _createInMemoryDatabase();
      sl.registerSingleton<Database>(database);
      _logWarning(
        action: 'register',
        result: 'degraded',
        code: 'storage_in_memory_database_registered',
      );
    }

    _registerRepositories();
    _logWarning(
      action: 'register',
      result: 'degraded',
      code: 'storage_register_completed_degraded',
      context: 'durationMs=${stopwatch.elapsedMilliseconds}',
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
    if (!sl.isRegistered<SecurePayloadStore>() &&
        sl.isRegistered<SecureStorageRepository>()) {
      sl.registerLazySingleton<SecurePayloadStore>(
        () => sl<SecureStorageRepository>(),
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

    if (!sl.isRegistered<content_cache_repo.ContentCacheRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<content_cache_repo.ContentCacheRepository>(
        () => content_cache_repo.ContentCacheRepository(sl<Database>()),
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

    if (!sl.isRegistered<SeriesSeenStateRepository>() &&
        sl.isRegistered<Database>()) {
      sl.registerLazySingleton<SeriesSeenStateRepository>(
        () => SeriesSeenStateRepositoryImpl(sl<Database>()),
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
        () => IptvLocalRepository(
          sl<Database>(),
          ownerIdProvider: () {
            if (!sl.isRegistered<AuthRepository>()) {
              return null;
            }
            return sl<AuthRepository>().currentSession?.userId;
          },
        ),
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
    debugPrint('[Storage][debug] $message');
  }

  static void _logWarning({
    required String action,
    required String result,
    String? code,
    String? context,
  }) {
    final codePart = (code == null || code.isEmpty) ? '' : ' code=$code';
    final contextPart = (context == null || context.isEmpty)
        ? ''
        : ' context=$context';
    final message =
        '[Storage] action=$action result=$result$codePart$contextPart';
    if (sl.isRegistered<AppLogger>()) {
      sl<AppLogger>().warn(message, category: 'storage');
      return;
    }
    debugPrint(message);
  }

  static void _logError({
    required String action,
    required String code,
    String? context,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final contextPart = (context == null || context.isEmpty)
        ? ''
        : ' context=$context';
    final message =
        '[Storage] action=$action result=failure code=$code$contextPart';
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

    debugPrint(message);
    if (kDebugMode) {
      debugPrint(
        '[Storage][debug] action=$action result=failure code=$code '
        'error=$error stackTrace=$stackTrace',
      );
    }
  }
}
