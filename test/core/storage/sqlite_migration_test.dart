import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database.dart';

import '../../helpers/database_initializer.dart';

Future<String> _dbPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'movi.db');
}

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test('migrates v1 -> v4 and creates new tables', () async {
    final path = await _dbPath();
    // Ensure a fresh start
    if (await File(path).exists()) {
      await deleteDatabase(path);
    }

    // Create a v1 database (watchlist, content_cache, iptv tables only)
    final v1 = await openDatabase(
      path,
      version: 1,
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
      },
    );
    await v1.close();

    // Reopen via LocalDatabase (current schema v4) to trigger migrations
    final db = await LocalDatabase.instance();

    // Verify new tables exist
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final names = tables.map((row) => row['name'] as String).toSet();

    expect(names.contains('continue_watching'), isTrue);
    expect(names.contains('history'), isTrue);
    expect(names.contains('playlists'), isTrue);
    expect(names.contains('playlist_items'), isTrue);
    // Existing tables should remain
    expect(names.contains('watchlist'), isTrue);
    expect(names.contains('content_cache'), isTrue);
  });
}

