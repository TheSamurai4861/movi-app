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
          owner_id TEXT NOT NULL,
          account_id TEXT NOT NULL,
          alias TEXT NOT NULL,
          endpoint TEXT NOT NULL,
          mac_address TEXT NOT NULL,
          username TEXT,
          token TEXT,
          status TEXT NOT NULL,
          expiration INTEGER,
          created_at INTEGER NOT NULL,
          last_error TEXT,
          PRIMARY KEY (owner_id, account_id)
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
    await _ensureTable(
      db,
      table: 'series_seen_state',
      ddl: '''
        CREATE TABLE series_seen_state (
          series_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          marked_at INTEGER NOT NULL,
          season INTEGER,
          episode INTEGER,
          PRIMARY KEY (series_id, user_id)
        );
      ''',
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
      _logDebug('enable_wal skipped reason=ios');
      return;
    }

    try {
      final result = await db.rawQuery('PRAGMA journal_mode = WAL;');
      _logDebug('enable_wal success result=$result');
    } on DatabaseException catch (error) {
      _logWarn(
        action: 'enable_wal',
        result: 'degraded',
        code: 'db_enable_wal_failed',
        context: 'type=${error.runtimeType}',
      );
      _logDebug('enable_wal error=$error');
    } catch (error) {
      _logWarn(
        action: 'enable_wal',
        result: 'degraded',
        code: 'db_enable_wal_unexpected_error',
        context: 'type=${error.runtimeType}',
      );
      _logDebug('enable_wal unexpected_error=$error');
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
      _logWarn(
        action: 'ensure_column',
        result: 'degraded',
        code: 'db_ensure_column_failed',
        context: 'table=$table column=$column type=${error.runtimeType}',
      );
      _logDebug('ensure_column error=$error table=$table column=$column');
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
      _logDebug('ensure_table created table=$table');
    } catch (error) {
      _logWarn(
        action: 'ensure_table',
        result: 'degraded',
        code: 'db_ensure_table_failed',
        context: 'table=$table type=${error.runtimeType}',
      );
      _logDebug('ensure_table error=$error table=$table');
    }
  }
}

void _logDebug(String message) {
  if (!kDebugMode) return;
  debugPrint('[StorageDbMaintenance][debug] $message');
}

void _logWarn({
  required String action,
  required String result,
  String? code,
  String? context,
}) {
  final codePart = (code == null || code.isEmpty) ? '' : ' code=$code';
  final contextPart = (context == null || context.isEmpty)
      ? ''
      : ' context=$context';
  debugPrint(
    '[StorageDbMaintenance] action=$action result=$result$codePart$contextPart',
  );
}
