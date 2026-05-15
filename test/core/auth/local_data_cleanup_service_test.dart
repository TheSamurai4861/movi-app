import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/auth/application/services/local_data_cleanup_service.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> openTestDb() {
    return openDatabase(
      inMemoryDatabasePath,
      version: 25,
      onCreate: (db, version) => LocalDatabaseSchema.create(db, version),
      onUpgrade: (db, oldVersion, newVersion) =>
          LocalDatabaseMigrations.upgrade(db, oldVersion, newVersion),
    );
  }

  test('clearAllLocalData wipes account, profiles and catalog tables', () async {
    final db = await openTestDb();
    final sl = GetIt.asNewInstance();
    addTearDown(() async {
      await db.close();
      await sl.reset();
    });

    await db.insert('local_profiles', <String, Object?>{
      'id': 'profile-1',
      'account_id': 'user-1',
      'name': 'Main',
      'color': 0xFF2160AB,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'is_kid': 0,
      'has_pin': 0,
    });
    await db.insert('entry_boot_state', <String, Object?>{
      'account_id': 'user-1',
      'profile_selected_locally': 1,
      'source_selected_locally': 1,
      'selected_profile_id': 'profile-1',
      'selected_source_id': 'source-1',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.insert('iptv_accounts', <String, Object?>{
      'owner_id': 'user-1',
      'account_id': 'source-1',
      'alias': 'Source',
      'endpoint': 'http://example.com',
      'username': 'demo',
      'status': 'active',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.insert('iptv_playlists_v2', <String, Object?>{
      'owner_id': 'user-1',
      'account_id': 'source-1',
      'playlist_id': 'playlist-1',
      'title': 'Films',
      'type': 'movies',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.insert('content_cache', <String, Object?>{
      'cache_key': 'catalog.source-1',
      'cache_type': 'iptv_catalog',
      'payload': '{"ok":true}',
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });

    final service = LocalDataCleanupService(db: db, sl: sl);
    await service.clearAllLocalData();

    expect(await db.query('local_profiles'), isEmpty);
    expect(await db.query('entry_boot_state'), isEmpty);
    expect(await db.query('iptv_accounts'), isEmpty);
    expect(await db.query('iptv_playlists_v2'), isEmpty);
    expect(await db.query('content_cache'), isEmpty);
  });
}
