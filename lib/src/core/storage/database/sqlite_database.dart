import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/storage/database/sqlite_database_maintenance.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_paths.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';

/// SQLite singleton (sqflite / sqflite_ffi) avec migrations.
/// - Version 21 (suivi de notification idempotent pour nouveaux épisodes)
/// - Version 20 (suivi local des séries et état NEW pour nouveaux épisodes)
/// - Version 19 (mémorisation de la variante/“version” choisie par contenu)
/// - Version 18 (ajout des profils locaux pour boot local-first)
/// - Version 17 (normalisation IPTV: iptv_playlists_v2 + iptv_playlist_items_v2)
/// - Version 11 (ajout colonne year à playlist_items pour stocker l'année des médias)
/// - Version 12 (ajout colonne is_pinned à playlists pour épingler des playlists utilisateur)
/// - Version 13 (ajout table iptv_playlist_settings pour ordre/visibilité des playlists IPTV)
/// - Version 14 (ajout colonne global_position à iptv_playlist_settings)
/// - Version 15 (ajout user_id à history et continue_watching)
/// - Version 10 (ajout colonne extension à playlist_items pour container_extension)
/// - Version 9 (ajout table iptv_episodes pour stocker les épisodes IPTV)
/// - Version 8 (ajout user_id à watchlist pour favoris par utilisateur)
/// - Version 7 (indexes cache supplémentaires, PRAGMA renforcés)
/// - Version 6 (retire colonne password de iptv_accounts)
/// - Desktop Windows utilise sqflite_common_ffi
class LocalDatabase {
  LocalDatabase._();

  static Database? _instance;

  /// Retourne l'instance unique de la base (créée au besoin).
  static Future<Database> instance() async {
    if (_instance != null) {
      return _instance!;
    }

    final sw = Stopwatch()..start();
    debugPrint(
      '[DEBUG][Startup] LocalDatabase.instance: Initializing database...',
    );

    final path = await LocalDatabasePaths.resolvePath();

    debugPrint(
      '[DEBUG][Startup] LocalDatabase.instance: opening database (version 21)',
    );
    _instance = await openDatabase(
      path,
      version: 21,
      onConfigure: (db) async {
        debugPrint('[DEBUG][Startup] LocalDatabase.instance: onConfigure');
        await LocalDatabaseMaintenance.onConfigure(db);
      },
      onOpen: (db) async {
        debugPrint(
          '[DEBUG][Startup] LocalDatabase.instance: onOpen (ensuring columns)',
        );
        await LocalDatabaseMaintenance.onOpen(db);
      },
      onCreate: (db, version) async {
        debugPrint(
          '[DEBUG][Startup] LocalDatabase.instance: onCreate (version $version)',
        );
        await LocalDatabaseSchema.create(db, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint(
          '[DEBUG][Startup] LocalDatabase.instance: onUpgrade (from $oldVersion to $newVersion)',
        );
        await LocalDatabaseMigrations.upgrade(db, oldVersion, newVersion);
      },
    );

    sw.stop();
    debugPrint(
      '[DEBUG][Startup] LocalDatabase.instance: COMPLETE (total: ${sw.elapsedMilliseconds}ms)',
    );

    return _instance!;
  }

  static Future<void> dispose() async {
    if (_instance == null) return;
    await _instance!.close();
    _instance = null;
  }
}
