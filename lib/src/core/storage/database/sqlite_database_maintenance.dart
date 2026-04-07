import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Best-effort database maintenance executed during open/configure callbacks.
final class LocalDatabaseMaintenance {
  const LocalDatabaseMaintenance._();

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    await _tryEnableWal(db);
  }

  static Future<void> onOpen(Database db) async {
    await _ensureColumn(
      db,
      table: 'playlist_items',
      column: 'year',
      ddlType: 'INTEGER',
    );
    await _ensureColumn(
      db,
      table: 'playlists',
      column: 'is_pinned',
      ddlType: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      table: 'iptv_playlist_settings',
      column: 'global_position',
      ddlType: 'INTEGER',
    );
    await _ensureColumn(
      db,
      table: 'history',
      column: 'user_id',
      ddlType: "TEXT NOT NULL DEFAULT 'default'",
    );
    await _ensureColumn(
      db,
      table: 'continue_watching',
      column: 'user_id',
      ddlType: "TEXT NOT NULL DEFAULT 'default'",
    );
    await _ensureTable(
      db,
      table: 'stalker_accounts',
      ddl: '''
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
      ''',
    );
    await _ensureColumn(
      db,
      table: 'tracked_series',
      column: 'last_notified_season',
      ddlType: 'INTEGER',
    );
    await _ensureColumn(
      db,
      table: 'tracked_series',
      column: 'last_notified_episode',
      ddlType: 'INTEGER',
    );
    await _ensureColumn(
      db,
      table: 'tracked_series',
      column: 'last_notified_at',
      ddlType: 'INTEGER',
    );
  }

  static Future<void> ensureColumn(
    Database db, {
    required String table,
    required String column,
    required String ddlType,
  }) => _ensureColumn(db, table: table, column: column, ddlType: ddlType);

  static Future<void> _tryEnableWal(Database db) async {
    if (Platform.isIOS) {
      debugPrint('[DB] Skipping PRAGMA journal_mode = WAL on iOS');
      return;
    }

    try {
      final result = await db.rawQuery('PRAGMA journal_mode = WAL;');
      debugPrint('[DB] WAL journal_mode result: $result');
    } on DatabaseException catch (error) {
      debugPrint('[DB] Failed to enable WAL, continuing without WAL: $error');
    } catch (error) {
      debugPrint(
        '[DB] Unexpected error while enabling WAL, continuing: $error',
      );
    }
  }

  static Future<void> _ensureColumn(
    Database db, {
    required String table,
    required String column,
    required String ddlType,
  }) async {
    try {
      final tableExists = await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1;",
        [table],
      );
      if (tableExists.isEmpty) return;

      final columns = await db.rawQuery('PRAGMA table_info($table);');
      final hasColumn = columns.any(
        (entry) => entry['name']?.toString() == column,
      );
      if (hasColumn) return;

      await db.execute('ALTER TABLE $table ADD COLUMN $column $ddlType;');
    } catch (error) {
      debugPrint('[DB] _ensureColumn($table.$column) failed: $error');
    }
  }

  static Future<void> _ensureTable(
    Database db, {
    required String table,
    required String ddl,
  }) async {
    try {
      final tableExists = await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? LIMIT 1;",
        [table],
      );
      if (tableExists.isNotEmpty) return;

      await db.execute(ddl);
      debugPrint('[DB] Created table $table');
    } catch (error) {
      debugPrint('[DB] _ensureTable($table) failed: $error');
    }
  }
}
