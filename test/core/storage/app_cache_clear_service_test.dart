import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';
import 'package:movi/src/core/storage/repositories/content_cache_repository.dart';
import 'package:movi/src/core/storage/services/app_cache_clear_service.dart';

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

  test('protected prefixes cover playback sync and subtitle appearance', () {
    expect(
      AppCacheClearService.protectedSecureStorageKeyPrefixes,
      contains(PlaybackSyncOffsetPreferences.defaultStorageKeyPrefix),
    );
    expect(
      AppCacheClearService.protectedSecureStorageKeyPrefixes,
      contains(SubtitleAppearancePreferences.defaultStorageKeyPrefix),
    );
  });

  test('clearAppCaches empties content_cache', () async {
    final db = await openTestDb();
    addTearDown(db.close);

    final repository = ContentCacheRepository(db);
    await repository.put(
      key: 'tmdb_movie_detail_1_en',
      type: 'tmdb_detail',
      payload: const {'id': 1},
    );

    final service = AppCacheClearService(
      contentCache: repository,
      clearImageDiskCache: () async {},
    );
    await service.clearAppCaches();

    expect(await db.query('content_cache'), isEmpty);
  });
}
