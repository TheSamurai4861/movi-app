import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  LocalDatabase._();

  static Database? _instance;

  static Future<Database> instance() async {
    if (_instance != null) return _instance!;

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'movi.db');

    _instance = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
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
            password TEXT NOT NULL,
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
      },
    );

    return _instance!;
  }
}
