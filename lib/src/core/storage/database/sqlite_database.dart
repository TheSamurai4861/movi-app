import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite singleton (sqflite / sqflite_ffi) avec migrations.
/// - Version 7 (indexes cache supplémentaires, PRAGMA renforcés)
/// - Version 6 (retire colonne password de iptv_accounts)
/// - Desktop (Windows/Linux) utilise sqflite_common_ffi
class LocalDatabase {
  LocalDatabase._();

  static Database? _instance;

  /// Retourne l'instance unique de la base (créée au besoin).
  static Future<Database> instance() async {
    if (_instance != null) return _instance!;

    try {
      WidgetsFlutterBinding.ensureInitialized();
    } catch (_) {}

    // Initialisation FFI pour desktop.
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();

    // S’assure que le dossier existe (surtout côté desktop portable).
    try {
      await Directory(dir.path).create(recursive: true);
    } catch (_) {}

    final path = p.join(dir.path, 'movi.db');

    _instance = await openDatabase(
      path,
      version: 7,
      onConfigure: (db) async {
        // Toujours activer les foreign keys.
        await db.execute('PRAGMA foreign_keys = ON;');

        // WAL = optimisation, jamais bloquante.
        await _tryEnableWal(db);
      },
      onCreate: (db, version) async {
        // --- Tables de base ---
        await db.execute('''
          CREATE TABLE watchlist (
            content_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            title TEXT NOT NULL,
            poster TEXT,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (content_id, content_type)
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
          CREATE TABLE iptv_playlists (
            account_id TEXT NOT NULL,
            category_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (account_id, category_id)
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
            PRIMARY KEY (content_id, content_type)
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
            PRIMARY KEY (content_id, content_type)
          );
        ''');

        // User playlists
        await db.execute('''
          CREATE TABLE playlists (
            playlist_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            cover TEXT,
            owner TEXT NOT NULL,
            is_public INTEGER NOT NULL,
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
            runtime INTEGER,
            notes TEXT,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (playlist_id, position)
          );
        ''');

        // --- Indexes (installations fraîches v5+) ---
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_iptv_playlists_account ON iptv_playlists(account_id);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_content_cache_updated_at ON content_cache(updated_at);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_content_cache_type ON content_cache(cache_type);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
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
              PRIMARY KEY (content_id, content_type)
            );
          ''');
        }
        if (oldVersion < 3) {
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
              PRIMARY KEY (content_id, content_type)
            );
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE playlists (
              playlist_id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT,
              cover TEXT,
              owner TEXT NOT NULL,
              is_public INTEGER NOT NULL,
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
              runtime INTEGER,
              notes TEXT,
              added_at INTEGER NOT NULL,
              PRIMARY KEY (playlist_id, position)
            );
          ''');
        }
        if (oldVersion < 5) {
          // Ajout des indexes pour accélérer les accès fréquents
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_iptv_playlists_account ON iptv_playlists(account_id);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_content_cache_updated_at ON content_cache(updated_at);',
          );
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE iptv_accounts_new (
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
            INSERT INTO iptv_accounts_new (
              account_id, alias, endpoint, username, status, expiration, created_at, last_error
            )
            SELECT account_id, alias, endpoint, username, status, expiration, created_at, last_error
            FROM iptv_accounts;
          ''');
          await db.execute('DROP TABLE iptv_accounts;');
          await db.execute(
            'ALTER TABLE iptv_accounts_new RENAME TO iptv_accounts;',
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_content_cache_type ON content_cache(cache_type);',
          );
        }
      },
    );

    return _instance!;
  }

  static Future<void> dispose() async {
    if (_instance == null) return;
    await _instance!.close();
    _instance = null;
  }

  /// Active WAL en "best effort" : jamais bloquant, surtout sur iOS où
  /// `PRAGMA journal_mode = WAL` peut lever une DatabaseException.
  static Future<void> _tryEnableWal(Database db) async {
    // Pas de WAL sur iOS : source de DatabaseException "not an error".
    if (Platform.isIOS) {
      debugPrint('[DB] Skipping PRAGMA journal_mode = WAL on iOS');
      return;
    }

    try {
      final result = await db.rawQuery('PRAGMA journal_mode = WAL;');
      debugPrint('[DB] WAL journal_mode result: $result');
    } on DatabaseException catch (e) {
      debugPrint(
        '[DB] Failed to enable WAL, continuing without WAL: $e',
      );
      // On n'échoue pas l'init : WAL est une optimisation seulement.
    } catch (e) {
      debugPrint(
        '[DB] Unexpected error while enabling WAL, continuing: $e',
      );
    }
  }
}
