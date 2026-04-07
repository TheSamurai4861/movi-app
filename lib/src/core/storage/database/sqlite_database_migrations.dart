import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database_maintenance.dart';

/// Runs incremental SQLite migrations for existing installations.
final class LocalDatabaseMigrations {
  const LocalDatabaseMigrations._();

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
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
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE watchlist_new (
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
        INSERT INTO watchlist_new (
          content_id, content_type, title, poster, added_at, user_id
        )
        SELECT content_id, content_type, title, poster, added_at, 'default'
        FROM watchlist;
      ''');
      await db.execute('DROP TABLE watchlist;');
      await db.execute('ALTER TABLE watchlist_new RENAME TO watchlist;');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_watchlist_user_id ON watchlist(user_id);',
      );
    }
    if (oldVersion < 16) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_outbox (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          entity TEXT NOT NULL,
          entity_key TEXT NOT NULL,
          op TEXT NOT NULL,
          payload TEXT,
          created_at INTEGER NOT NULL
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sync_outbox_user_created ON sync_outbox(user_id, created_at);',
      );
    }
    if (oldVersion < 17) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS iptv_playlists_v2 (
          account_id TEXT NOT NULL,
          playlist_id TEXT NOT NULL,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (account_id, playlist_id)
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS iptv_playlist_items_v2 (
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

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_iptv_playlists_v2_account ON iptv_playlists_v2(account_id);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_items_v2_account_playlist_pos ON iptv_playlist_items_v2(account_id, playlist_id, position);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_items_v2_account_title ON iptv_playlist_items_v2(account_id, title);',
      );
    }
    if (oldVersion < 18) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_profiles (
          id TEXT PRIMARY KEY,
          account_id TEXT NOT NULL,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          avatar_url TEXT,
          created_at INTEGER,
          updated_at INTEGER NOT NULL,
          is_kid INTEGER NOT NULL DEFAULT 0,
          pegi_limit INTEGER,
          has_pin INTEGER NOT NULL DEFAULT 0
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_local_profiles_account_created ON local_profiles(account_id, created_at);',
      );
    }
    if (oldVersion < 19) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS playback_variant_selection (
          content_id TEXT NOT NULL,
          content_type TEXT NOT NULL,
          variant_id TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          user_id TEXT NOT NULL DEFAULT 'default',
          PRIMARY KEY (content_id, content_type, user_id)
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_playback_variant_selection_user_type_updated ON playback_variant_selection(user_id, content_type, updated_at);',
      );
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE iptv_episodes (
          account_id TEXT NOT NULL,
          series_id INTEGER NOT NULL,
          season_number INTEGER NOT NULL,
          episode_number INTEGER NOT NULL,
          episode_id INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (account_id, series_id, season_number, episode_number)
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_iptv_episodes_account_series ON iptv_episodes(account_id, series_id);',
      );
    }
    if (oldVersion < 10) {
      await db.execute('ALTER TABLE iptv_episodes ADD COLUMN extension TEXT;');
    }
    if (oldVersion < 11) {
      await db.execute('ALTER TABLE playlist_items ADD COLUMN year INTEGER;');
    }
    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE playlists ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0;',
      );
    }
    if (oldVersion < 13) {
      await db.execute('''
        CREATE TABLE iptv_playlist_settings (
          account_id TEXT NOT NULL,
          playlist_id TEXT NOT NULL,
          type TEXT NOT NULL,
          position INTEGER NOT NULL,
          global_position INTEGER NOT NULL DEFAULT 0,
          is_visible INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (account_id, playlist_id)
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_settings_account_type_pos ON iptv_playlist_settings(account_id, type, position);',
      );
    }
    if (oldVersion < 14) {
      await LocalDatabaseMaintenance.ensureColumn(
        db,
        table: 'iptv_playlist_settings',
        column: 'global_position',
        ddlType: 'INTEGER',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_settings_account_global_pos ON iptv_playlist_settings(account_id, global_position);',
      );
      await _initializeGlobalPlaylistPositions(db);
    }

    if (oldVersion < 15) {
      await db.execute('''
        CREATE TABLE continue_watching_new (
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
        INSERT INTO continue_watching_new (
          content_id, content_type, title, poster, position, duration, season, episode, updated_at, user_id
        )
        SELECT content_id, content_type, title, poster, position, duration, season, episode, updated_at, 'default'
        FROM continue_watching;
      ''');
      await db.execute('DROP TABLE continue_watching;');
      await db.execute(
        'ALTER TABLE continue_watching_new RENAME TO continue_watching;',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_continue_watching_user_type_updated ON continue_watching(user_id, content_type, updated_at);',
      );

      await db.execute('''
        CREATE TABLE history_new (
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
        INSERT INTO history_new (
          content_id, content_type, title, poster, last_played_at, play_count, last_position, duration, season, episode, user_id
        )
        SELECT content_id, content_type, title, poster, last_played_at, play_count, last_position, duration, season, episode, 'default'
        FROM history;
      ''');
      await db.execute('DROP TABLE history;');
      await db.execute('ALTER TABLE history_new RENAME TO history;');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_user_type_played ON history(user_id, content_type, last_played_at);',
      );
    }
    if (oldVersion < 20) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tracked_series (
          series_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          title TEXT NOT NULL,
          poster TEXT,
          last_known_season INTEGER,
          last_known_episode INTEGER,
          last_known_air_date INTEGER,
          last_checked_at INTEGER,
          has_new_episode INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (series_id, user_id)
        );
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tracked_series_user_id ON tracked_series(user_id);',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tracked_series_new_episode ON tracked_series(user_id, has_new_episode);',
      );
    }

    if (oldVersion < 21) {
      await LocalDatabaseMaintenance.ensureColumn(
        db,
        table: 'tracked_series',
        column: 'last_notified_season',
        ddlType: 'INTEGER',
      );
      await LocalDatabaseMaintenance.ensureColumn(
        db,
        table: 'tracked_series',
        column: 'last_notified_episode',
        ddlType: 'INTEGER',
      );
      await LocalDatabaseMaintenance.ensureColumn(
        db,
        table: 'tracked_series',
        column: 'last_notified_at',
        ddlType: 'INTEGER',
      );
    }
  }

  static Future<void> _initializeGlobalPlaylistPositions(Database db) async {
    final rows = await db.query(
      'iptv_playlist_settings',
      columns: ['account_id', 'playlist_id', 'type', 'position'],
    );

    final byAccount = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final accountId = (row['account_id'] as String?) ?? '';
      if (accountId.isEmpty) continue;
      byAccount.putIfAbsent(accountId, () => <Map<String, Object?>>[]).add(row);
    }

    for (final entry in byAccount.entries) {
      final accountId = entry.key;
      final list = entry.value;

      final movies = <Map<String, Object?>>[];
      final series = <Map<String, Object?>>[];
      for (final row in list) {
        final type = (row['type'] as String?) ?? '';
        if (type == 'series') {
          series.add(row);
        } else {
          movies.add(row);
        }
      }

      int positionOf(Map<String, Object?> row) =>
          (row['position'] as int?) ?? 0;

      movies.sort((a, b) => positionOf(a).compareTo(positionOf(b)));
      series.sort((a, b) => positionOf(a).compareTo(positionOf(b)));

      final ordered = <Map<String, Object?>>[];
      final maxLen = movies.length > series.length
          ? movies.length
          : series.length;
      for (var index = 0; index < maxLen; index++) {
        if (index < movies.length) ordered.add(movies[index]);
        if (index < series.length) ordered.add(series[index]);
      }

      final batch = db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (var index = 0; index < ordered.length; index++) {
        final playlistId = (ordered[index]['playlist_id'] as String?) ?? '';
        if (playlistId.isEmpty) continue;
        batch.update(
          'iptv_playlist_settings',
          {'global_position': index, 'updated_at': now},
          where: 'account_id = ? AND playlist_id = ?',
          whereArgs: [accountId, playlistId],
        );
      }
      await batch.commit(noResult: true);
    }
  }
}
