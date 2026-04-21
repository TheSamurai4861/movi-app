import 'dart:io';

import 'package:flutter/foundation.dart';
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

    _logDebug('resolve_path get_application_support_directory');
    final newDir = await getApplicationSupportDirectory();

    try {
      await Directory(newDir.path).create(recursive: true);
    } catch (_) {}

    final newPath = p.join(newDir.path, fileName);
    _logDebug('resolve_path target=$newPath');

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

    _logDebug('configure_factory platform=windows init=sqflite_ffi');
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
      _logDebug('migrate_database start source=documents target=app_support');
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
      _logDebug('migrate_database success');
    } catch (error) {
      _logWarn(
        action: 'migrate_database',
        result: 'degraded',
        code: 'db_path_migration_failed',
        context: 'type=${error.runtimeType}',
      );
      _logDebug('migrate_database error=$error');
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

void _logDebug(String message) {
  if (!kDebugMode) return;
  debugPrint('[StorageDbPath][debug] $message');
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
    '[StorageDbPath] action=$action result=$result$codePart$contextPart',
  );
}
