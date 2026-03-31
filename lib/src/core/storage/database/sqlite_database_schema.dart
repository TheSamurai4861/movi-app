import 'package:sqflite/sqflite.dart';

/// Creates the full schema for fresh SQLite installations.
final class LocalDatabaseSchema {
  const LocalDatabaseSchema._();

  static Future<void> create(Database db, int version) async {
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
      CREATE TABLE IF NOT EXISTS stalker_accounts (
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
      CREATE TABLE iptv_playlists (
        account_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (account_id, category_id)
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
      CREATE TABLE iptv_episodes (
        account_id TEXT NOT NULL,
        series_id INTEGER NOT NULL,
        season_number INTEGER NOT NULL,
        episode_number INTEGER NOT NULL,
        episode_id INTEGER NOT NULL,
        extension TEXT,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (account_id, series_id, season_number, episode_number)
      );
    ''');

    await db.execute('''
      CREATE TABLE iptv_playlist_settings (
        account_id TEXT NOT NULL,
        playlist_id TEXT NOT NULL,
        type TEXT NOT NULL,
        position INTEGER NOT NULL,
        global_position INTEGER NOT NULL,
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
      CREATE TABLE playback_variant_selection (
        content_id TEXT NOT NULL,
        content_type TEXT NOT NULL,
        variant_id TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
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

    await db.execute('''
      CREATE TABLE local_profiles (
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
      'CREATE INDEX IF NOT EXISTS idx_iptv_playlists_account ON iptv_playlists(account_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iptv_playlists_v2_account ON iptv_playlists_v2(account_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_items_v2_account_playlist_pos ON iptv_playlist_items_v2(account_id, playlist_id, position);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_items_v2_account_title ON iptv_playlist_items_v2(account_id, title);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iptv_episodes_account_series ON iptv_episodes(account_id, series_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_settings_account_type_pos ON iptv_playlist_settings(account_id, type, position);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_settings_account_global_pos ON iptv_playlist_settings(account_id, global_position);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_content_cache_updated_at ON content_cache(updated_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_content_cache_type ON content_cache(cache_type);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_outbox_user_created ON sync_outbox(user_id, created_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_history_user_type_played ON history(user_id, content_type, last_played_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_playback_variant_selection_user_type_updated ON playback_variant_selection(user_id, content_type, updated_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_continue_watching_user_type_updated ON continue_watching(user_id, content_type, updated_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_profiles_account_created ON local_profiles(account_id, created_at);',
    );
  }
}
