import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite singleton (sqflite / sqflite_ffi) avec migrations.
/// - Version 17 (normalisation IPTV: iptv_playlists_v2 + iptv_playlist_items_v2)
/// - Version 11 (ajout colonne year à playlist_items pour stocker l'année des médias)
/// - Version 12 (ajout colonne is_pinned à playlists pour épingler des playlists utilisateur)
/// - Version 13 (ajout table iptv_playlist_settings pour ordre/visibilité des playlists IPTV)
/// - Version 14 (ajout colonne global_position à iptv_playlist_settings)
/// - Version 15 (ajout user_id à history et continue_watching)
/// - Version 10 (ajout colonne extension à iptv_episodes pour container_extension)
/// - Version 9 (ajout table iptv_episodes pour stocker les épisodes IPTV)
/// - Version 8 (ajout user_id à watchlist pour favoris par utilisateur)
/// - Version 7 (indexes cache supplémentaires, PRAGMA renforcés)
/// - Version 6 (retire colonne password de iptv_accounts)
/// - Desktop (Windows/Linux) utilise sqflite_common_ffi
class LocalDatabase {
  LocalDatabase._();

  static Database? _instance;

  /// Retourne l'instance unique de la base (créée au besoin).
  static Future<Database> instance() async {
    if (_instance != null) {
      return _instance!;
    }

    final sw = Stopwatch()..start();
    debugPrint('[DEBUG][Startup] LocalDatabase.instance: Initializing database...');

    try {
      WidgetsFlutterBinding.ensureInitialized();
    } catch (_) {}

    // Initialisation FFI pour desktop.
    if (Platform.isWindows || Platform.isLinux) {
      debugPrint('[DEBUG][Startup] LocalDatabase.instance: initializing sqflite_ffi for desktop');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // 1. Obtenir le nouveau dossier (Application Support - inaccessible à l'utilisateur)
    debugPrint('[DEBUG][Startup] LocalDatabase.instance: getting application support directory');
    final newDir = await getApplicationSupportDirectory();

    // S’assure que le dossier existe (surtout côté desktop portable).
    try {
      await Directory(newDir.path).create(recursive: true);
    } catch (_) {}

    final newPath = p.join(newDir.path, 'movi.db');
    debugPrint('[DEBUG][Startup] LocalDatabase.instance: database path = $newPath');

    // 2. Migration des données existantes depuis l'ancien emplacement si nécessaire
    final oldDir = await getApplicationDocumentsDirectory();
    final oldPath = p.join(oldDir.path, 'movi.db');
    final oldDbFile = File(oldPath);
    final newDbFile = File(newPath);

    if (await oldDbFile.exists() && !await newDbFile.exists()) {
      try {
        debugPrint(
          '[DB] Migrating database from Documents to Application Support',
        );
        // Migrer la DB principale
        await oldDbFile.copy(newPath);

        // Migrer aussi les fichiers WAL si présents
        final oldWalPath = '$oldPath-wal';
        final newWalPath = '$newPath-wal';
        final oldWalFile = File(oldWalPath);
        if (await oldWalFile.exists()) {
          await oldWalFile.copy(newWalPath);
          await oldWalFile.delete();
        }

        final oldShmPath = '$oldPath-shm';
        final newShmPath = '$newPath-shm';
        final oldShmFile = File(oldShmPath);
        if (await oldShmFile.exists()) {
          await oldShmFile.copy(newShmPath);
          await oldShmFile.delete();
        }

        // Supprimer l'ancienne DB après migration réussie
        await oldDbFile.delete();
        debugPrint('[DB] Database migration completed successfully');
      } catch (e) {
        debugPrint('[DB] Failed to migrate database: $e');
        // Si la migration échoue, on continue avec le nouvel emplacement
        // L'ancienne DB reste en place comme backup
      }
    }

    final path = newPath;

    debugPrint('[DEBUG][Startup] LocalDatabase.instance: opening database (version 17)');
    _instance = await openDatabase(
      path,
      version: 17,
      onConfigure: (db) async {
        debugPrint('[DEBUG][Startup] LocalDatabase.instance: onConfigure');
        // Toujours activer les foreign keys.
        await db.execute('PRAGMA foreign_keys = ON;');

        // WAL = optimisation, jamais bloquante.
        await _tryEnableWal(db);
      },
      onOpen: (db) async {
        debugPrint('[DEBUG][Startup] LocalDatabase.instance: onOpen (ensuring columns)');
        // Défensif: certaines DB ont pu être créées avec une table `playlist_items`
        // sans la colonne `year` (malgré la version actuelle).
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
        // Créer la table stalker_accounts si elle n'existe pas (migration)
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
      },
      onCreate: (db, version) async {
        debugPrint('[DEBUG][Startup] LocalDatabase.instance: onCreate (version $version)');
        // --- Tables de base ---
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

        // Outbox générique pour synchronisation remote (Supabase, etc.)
        // NOTE: on stocke le payload en JSON string pour rester flexible.
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

        // User playlists
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

        // --- Indexes (installations fraîches v5+) ---
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
          'CREATE INDEX IF NOT EXISTS idx_continue_watching_user_type_updated ON continue_watching(user_id, content_type, updated_at);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('[DEBUG][Startup] LocalDatabase.instance: onUpgrade (from $oldVersion to $newVersion)');
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
        if (oldVersion < 8) {
          // Ajout de la colonne user_id à la table watchlist
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
        if (oldVersion < 9) {
          // Création de la table pour stocker les épisodes IPTV
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
          // Ajout de la colonne extension pour stocker container_extension
          await db.execute(
            'ALTER TABLE iptv_episodes ADD COLUMN extension TEXT;',
          );
        }
        if (oldVersion < 11) {
          // Ajout de la colonne year pour stocker l'année des médias dans playlist_items
          await db.execute(
            'ALTER TABLE playlist_items ADD COLUMN year INTEGER;',
          );
        }
        if (oldVersion < 12) {
          // Ajout de la colonne is_pinned pour épingler des playlists utilisateur
          await db.execute(
            'ALTER TABLE playlists ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0;',
          );
        }
        if (oldVersion < 13) {
          // Ajout de la table iptv_playlist_settings pour gérer ordre/visibilité
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
          // Ajout de la colonne global_position + initialisation (ordre intercalé par défaut).
          await _ensureColumn(
            db,
            table: 'iptv_playlist_settings',
            column: 'global_position',
            ddlType: 'INTEGER',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_iptv_playlist_settings_account_global_pos ON iptv_playlist_settings(account_id, global_position);',
          );

          final rows = await db.query(
            'iptv_playlist_settings',
            columns: ['account_id', 'playlist_id', 'type', 'position'],
          );

          final byAccount = <String, List<Map<String, Object?>>>{};
          for (final r in rows) {
            final acc = (r['account_id'] as String?) ?? '';
            if (acc.isEmpty) continue;
            byAccount.putIfAbsent(acc, () => <Map<String, Object?>>[]).add(r);
          }

          for (final entry in byAccount.entries) {
            final accountId = entry.key;
            final list = entry.value;

            final movies = <Map<String, Object?>>[];
            final series = <Map<String, Object?>>[];
            for (final r in list) {
              final t = (r['type'] as String?) ?? '';
              if (t == 'series') {
                series.add(r);
              } else {
                movies.add(r);
              }
            }

            int posOf(Map<String, Object?> r) => (r['position'] as int?) ?? 0;

            movies.sort((a, b) => posOf(a).compareTo(posOf(b)));
            series.sort((a, b) => posOf(a).compareTo(posOf(b)));

            final ordered = <Map<String, Object?>>[];
            final maxLen = movies.length > series.length
                ? movies.length
                : series.length;
            for (var i = 0; i < maxLen; i++) {
              if (i < movies.length) ordered.add(movies[i]);
              if (i < series.length) ordered.add(series[i]);
            }

            final batch = db.batch();
            final now = DateTime.now().millisecondsSinceEpoch;
            for (var i = 0; i < ordered.length; i++) {
              final playlistId = (ordered[i]['playlist_id'] as String?) ?? '';
              if (playlistId.isEmpty) continue;
              batch.update(
                'iptv_playlist_settings',
                {'global_position': i, 'updated_at': now},
                where: 'account_id = ? AND playlist_id = ?',
                whereArgs: [accountId, playlistId],
              );
            }
            await batch.commit(noResult: true);
          }
        }

        if (oldVersion < 15) {
          // Ajout user_id à history + continue_watching pour supporter plusieurs profils.
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
      },
    );

    sw.stop();
    debugPrint('[DEBUG][Startup] LocalDatabase.instance: COMPLETE (total: ${sw.elapsedMilliseconds}ms)');
    
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
      debugPrint('[DB] Failed to enable WAL, continuing without WAL: $e');
      // On n'échoue pas l'init : WAL est une optimisation seulement.
    } catch (e) {
      debugPrint('[DB] Unexpected error while enabling WAL, continuing: $e');
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

      final cols = await db.rawQuery('PRAGMA table_info($table);');
      final has = cols.any((c) => c['name']?.toString() == column);
      if (has) return;

      await db.execute('ALTER TABLE $table ADD COLUMN $column $ddlType;');
    } catch (e) {
      // Best-effort : ne jamais bloquer l'ouverture de l'app pour une migration défensive.
      debugPrint('[DB] _ensureColumn($table.$column) failed: $e');
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
    } catch (e) {
      debugPrint('[DB] _ensureTable($table) failed: $e');
    }
  }
}
