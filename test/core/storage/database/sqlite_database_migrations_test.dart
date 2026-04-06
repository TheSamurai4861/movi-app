import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upgrades a version 13 storage schema to version 19 safely', () async {
    final db = await openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    await db.execute('''
      CREATE TABLE iptv_playlist_settings (
        account_id TEXT NOT NULL,
        playlist_id TEXT NOT NULL,
        type TEXT NOT NULL,
        position INTEGER NOT NULL,
        is_visible INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (account_id, playlist_id)
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

    await db.insert('iptv_playlist_settings', <String, Object?>{
      'account_id': 'acc-1',
      'playlist_id': 'movies-1',
      'type': 'movie',
      'position': 0,
      'is_visible': 1,
      'updated_at': 100,
    });
    await db.insert('iptv_playlist_settings', <String, Object?>{
      'account_id': 'acc-1',
      'playlist_id': 'series-1',
      'type': 'series',
      'position': 0,
      'is_visible': 1,
      'updated_at': 100,
    });
    await db.insert('iptv_playlist_settings', <String, Object?>{
      'account_id': 'acc-1',
      'playlist_id': 'movies-2',
      'type': 'movie',
      'position': 1,
      'is_visible': 1,
      'updated_at': 100,
    });
    await db.insert('continue_watching', <String, Object?>{
      'content_id': 'cw-1',
      'content_type': 'movie',
      'title': 'Continue Watching',
      'poster': null,
      'position': 42,
      'duration': 120,
      'season': null,
      'episode': null,
      'updated_at': 1,
    });
    await db.insert('history', <String, Object?>{
      'content_id': 'hist-1',
      'content_type': 'movie',
      'title': 'History Entry',
      'poster': null,
      'last_played_at': 2,
      'play_count': 1,
      'last_position': 84,
      'duration': 120,
      'season': null,
      'episode': null,
    });

    await LocalDatabaseMigrations.upgrade(db, 13, 19);

    final playlistSettings = await db.query(
      'iptv_playlist_settings',
      columns: <String>['playlist_id', 'global_position'],
      orderBy: 'global_position ASC',
    );
    expect(
      playlistSettings.map((row) => row['playlist_id']).toList(growable: false),
      <String>['movies-1', 'series-1', 'movies-2'],
    );

    final continueWatching = await db.query('continue_watching');
    final history = await db.query('history');
    expect(continueWatching.single['user_id'], 'default');
    expect(history.single['user_id'], 'default');

    final tables = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('sync_outbox', 'local_profiles', 'playback_variant_selection')
      ORDER BY name ASC;
    ''');
    final tableNames = tables
        .map((row) => row['name'] as String)
        .toList(growable: false);
    expect(
      tableNames,
      <String>['local_profiles', 'playback_variant_selection', 'sync_outbox'],
    );
  });
}
