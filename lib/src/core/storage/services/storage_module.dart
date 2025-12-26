import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/security/secure_credentials_vault.dart';
import 'package:movi/src/core/storage/database/sqlite_database.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/services/xtream_lookup.dart';
import 'package:movi/src/core/logging/logger.dart';

/// Registers all storage-layer dependencies.
///
/// In tests, prefer overriding repositories with in-memory fakes before calling
/// [register] to avoid touching the on-disk SQLite database.
class StorageModule {
  static Future<void> register() async {
    final sw = Stopwatch()..start();
    debugPrint('[DEBUG][Startup] StorageModule.register: START');
    
    try {
      if (!sl.isRegistered<Database>()) {
        debugPrint('[DEBUG][Startup] StorageModule.register: initializing LocalDatabase');
        final db = await LocalDatabase.instance().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('[DEBUG][Startup] StorageModule.register: WARNING - LocalDatabase.instance timeout');
            throw TimeoutException('LocalDatabase.instance timeout', const Duration(seconds: 10));
          },
        );
        sl.registerSingleton<Database>(db);
        debugPrint('[DEBUG][Startup] StorageModule.register: LocalDatabase registered (${sw.elapsedMilliseconds}ms)');
      }
      
      // Enregistrer les repositories
      _registerRepositories();
      
      sw.stop();
      debugPrint('[DEBUG][Startup] StorageModule.register: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
    } catch (e, st) {
      sw.stop();
      debugPrint('[DEBUG][Startup] StorageModule.register: ERROR after ${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[DEBUG][Startup] StorageModule.register: Stack trace: $st');
      
      // Fallback : enregistrer une DB en mémoire pour mode dégradé
      debugPrint('[DEBUG][Startup] StorageModule.register: Using in-memory fallback');
      
      try {
        if (!sl.isRegistered<Database>()) {
          final inMemoryDb = await _createInMemoryDatabase();
          sl.registerSingleton<Database>(inMemoryDb);
          debugPrint('[DEBUG][Startup] StorageModule.register: In-memory database registered');
        }
        _registerRepositories();
        debugPrint('[DEBUG][Startup] StorageModule.register: In-memory fallback registered successfully');
      } catch (fallbackError, fallbackSt) {
        debugPrint('[DEBUG][Startup] StorageModule.register: FATAL - Even fallback failed: $fallbackError');
        debugPrint('[DEBUG][Startup] StorageModule.register: Fallback stack trace: $fallbackSt');
        // Ne pas faire échouer le startup, mais logger clairement
        // L'app fonctionnera en mode cloud-only
      }
    }
  }

  /// Enregistre tous les repositories qui dépendent de la Database
  static void _registerRepositories() {
    if (!sl.isRegistered<SyncOutboxRepository>()) {
      sl.registerLazySingleton<SyncOutboxRepository>(
        () => SyncOutboxRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<ContentCacheRepository>()) {
      sl.registerLazySingleton<ContentCacheRepository>(
        () => ContentCacheRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<IptvLocalRepository>()) {
      sl.registerLazySingleton<IptvLocalRepository>(
        () => IptvLocalRepository(sl<Database>()),
      );
    }

    if (!sl.isRegistered<WatchlistLocalRepository>()) {
      sl.registerLazySingleton<WatchlistLocalRepository>(
        () => WatchlistLocalRepositoryImpl(
          db: sl<Database>(),
          outbox: sl<SyncOutboxRepository>(),
        ),
      );
    }

    if (!sl.isRegistered<HistoryLocalRepository>()) {
      sl.registerLazySingleton<HistoryLocalRepository>(
        () => HistoryLocalRepositoryImpl(sl<Database>()),
      );
    }

    if (!sl.isRegistered<ContinueWatchingLocalRepository>()) {
      sl.registerLazySingleton<ContinueWatchingLocalRepository>(
        () => ContinueWatchingLocalRepositoryImpl(sl<Database>()),
      );
    }

    if (!sl.isRegistered<PlaylistLocalRepository>()) {
      sl.registerLazySingleton<PlaylistLocalRepository>(
        () => PlaylistLocalRepository(
          db: sl<Database>(),
          outbox: sl<SyncOutboxRepository>(),
        ),
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

    if (!sl.isRegistered<XtreamLookupService>()) {
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

  /// Crée une base de données en mémoire pour le mode dégradé
  static Future<Database> _createInMemoryDatabase() async {
    debugPrint('[DEBUG][Startup] StorageModule: Creating in-memory database');
    return await openDatabase(
      inMemoryDatabasePath,
      version: 17,
      onCreate: (db, version) async {
        debugPrint('[DEBUG][Startup] StorageModule: Creating essential tables in memory');
        // Créer uniquement les tables essentielles pour mode dégradé
        await db.execute('''
          CREATE TABLE watchlist (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            added_at INTEGER NOT NULL,
            user_id TEXT NOT NULL DEFAULT 'default',
            PRIMARY KEY (content_id, content_type, user_id)
          );
        ''');
        
        await db.execute('''
          CREATE TABLE sync_outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            entity TEXT NOT NULL,
            entity_key TEXT NOT NULL,
            op TEXT NOT NULL,
            payload TEXT,
            created_at INTEGER NOT NULL
          );
        ''');
        
        await db.execute('''
          CREATE TABLE content_cache (
            cache_key TEXT PRIMARY KEY,
            cache_type TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        
        await db.execute('''
          CREATE TABLE iptv_accounts (
            account_id TEXT PRIMARY KEY,
            alias TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            username TEXT NOT NULL,
            status TEXT NOT NULL,
            expiration INTEGER,
            created_at INTEGER NOT NULL,
            last_error TEXT
          );
        ''');
        
        await db.execute('''
          CREATE TABLE stalker_accounts (
            account_id TEXT PRIMARY KEY,
            alias TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            mac_address TEXT NOT NULL,
            username TEXT,
            token TEXT,
            status TEXT NOT NULL,
            expiration INTEGER,
            created_at INTEGER NOT NULL,
            last_error TEXT
          );
        ''');
        
        await db.execute('''
          CREATE TABLE iptv_playlists_v2 (
            account_id TEXT NOT NULL,
            playlist_id TEXT NOT NULL,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (account_id, playlist_id)
          );
        ''');
        
        await db.execute('''
          CREATE TABLE iptv_playlist_items_v2 (
            account_id TEXT NOT NULL,
            playlist_id TEXT NOT NULL,
            stream_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            poster TEXT,
            tmdb_id INTEGER,
            container_extension TEXT,
            rating REAL,
            release_year INTEGER,
            PRIMARY KEY (account_id, playlist_id, stream_id)
          );
        ''');
        
        await db.execute('''
          CREATE TABLE continue_watching (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            position INTEGER NOT NULL,
            duration INTEGER,
            season INTEGER,
            episode INTEGER,
            updated_at INTEGER NOT NULL,
            user_id TEXT NOT NULL DEFAULT 'default',
            PRIMARY KEY (content_id, content_type, user_id)
          );
        ''');
        
        await db.execute('''
          CREATE TABLE history (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            last_played_at INTEGER NOT NULL,
            play_count INTEGER NOT NULL DEFAULT 1,
            last_position INTEGER,
            duration INTEGER,
            season INTEGER,
            episode INTEGER,
            user_id TEXT NOT NULL DEFAULT 'default',
            PRIMARY KEY (content_id, content_type, user_id)
          );
        ''');
        
        await db.execute('''
          CREATE TABLE playlists (
            playlist_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            cover TEXT,
            owner TEXT NOT NULL,
            is_public INTEGER NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          );
        ''');
        
        await db.execute('''
          CREATE TABLE playlist_items (
            playlist_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            year INTEGER,
            runtime INTEGER,
            notes TEXT,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, position)
          );
        ''');
        
        debugPrint('[DEBUG][Startup] StorageModule: In-memory database tables created');
      },
    );
  }

  static Future<void> dispose() async {
    await LocalDatabase.dispose();
    if (sl.isRegistered<Database>()) {
      sl.unregister<Database>();
    }
  }
}
