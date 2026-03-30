import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Resolves and prepares the on-disk SQLite path used by the app.
///
/// This helper keeps platform bootstrap and file migration details out of the
/// main database schema file so `LocalDatabase` can stay focused on opening the
/// database and wiring callbacks.
final class LocalDatabasePaths {
  const LocalDatabasePaths._();

  static const String fileName = 'movi.db';

  static Future<String> resolvePath() async {
    _ensureFlutterBindingInitialized();
    _configurePlatformDatabaseFactory();

    debugPrint(
      '[DEBUG][Startup] LocalDatabase.instance: getting application support directory',
    );
    final newDir = await getApplicationSupportDirectory();

    try {
      await Directory(newDir.path).create(recursive: true);
    } catch (_) {}

    final newPath = p.join(newDir.path, fileName);
    debugPrint(
      '[DEBUG][Startup] LocalDatabase.instance: database path = $newPath',
    );

    await _migrateDatabaseIfNeeded(newPath);
    return newPath;
  }

  static void _ensureFlutterBindingInitialized() {
    try {
      WidgetsFlutterBinding.ensureInitialized();
    } catch (_) {}
  }

  static void _configurePlatformDatabaseFactory() {
    if (!Platform.isWindows) return;

    debugPrint(
      '[DEBUG][Startup] LocalDatabase.instance: initializing sqflite_ffi for Windows',
    );
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  static Future<void> _migrateDatabaseIfNeeded(String newPath) async {
    final oldDir = await getApplicationDocumentsDirectory();
    final oldPath = p.join(oldDir.path, fileName);
    final oldDbFile = File(oldPath);
    final newDbFile = File(newPath);

    if (!await oldDbFile.exists() || await newDbFile.exists()) {
      return;
    }

    try {
      debugPrint(
        '[DB] Migrating database from Documents to Application Support',
      );
      await oldDbFile.copy(newPath);
      await _migrateCompanionFile(
        sourcePath: '$oldPath-wal',
        destinationPath: '$newPath-wal',
      );
      await _migrateCompanionFile(
        sourcePath: '$oldPath-shm',
        destinationPath: '$newPath-shm',
      );
      await oldDbFile.delete();
      debugPrint('[DB] Database migration completed successfully');
    } catch (error) {
      debugPrint('[DB] Failed to migrate database: $error');
    }
  }

  static Future<void> _migrateCompanionFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return;

    await sourceFile.copy(destinationPath);
    await sourceFile.delete();
  }
}
