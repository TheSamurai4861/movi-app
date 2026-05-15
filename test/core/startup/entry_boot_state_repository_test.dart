import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/startup/entry_boot_state_repository.dart';
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

  test('returns default snapshot when no row exists', () async {
    final db = await openTestDb();
    addTearDown(db.close);
    final repo = EntryBootStateRepository(db);

    final snapshot = await repo.read();

    expect(snapshot.accountId, EntryBootStateRepository.localAccountId);
    expect(snapshot.profileSelectedLocally, isFalse);
    expect(snapshot.sourceSelectedLocally, isFalse);
    expect(snapshot.firstLaunchCompletedAt, isNull);
  });

  test('persists confirmations and completion per account', () async {
    final db = await openTestDb();
    addTearDown(db.close);
    final repo = EntryBootStateRepository(db);

    await repo.confirmProfileSelected(
      accountId: 'user_a',
      profileId: 'profile_a',
    );
    await repo.confirmSourceSelected(
      accountId: 'user_a',
      sourceId: 'source_a',
    );
    await repo.markFirstLaunchCompleted(accountId: 'user_a');

    final snapshot = await repo.read(accountId: 'user_a');
    expect(snapshot.profileSelectedLocally, isTrue);
    expect(snapshot.selectedProfileId, 'profile_a');
    expect(snapshot.sourceSelectedLocally, isTrue);
    expect(snapshot.selectedSourceId, 'source_a');
    expect(snapshot.firstLaunchCompletedAt, isNotNull);
  });

  test('isolates state by account_id', () async {
    final db = await openTestDb();
    addTearDown(db.close);
    final repo = EntryBootStateRepository(db);

    await repo.confirmProfileSelected(
      accountId: 'user_a',
      profileId: 'profile_a',
    );
    await repo.confirmSourceSelected(
      accountId: 'user_b',
      sourceId: 'source_b',
    );

    final a = await repo.read(accountId: 'user_a');
    final b = await repo.read(accountId: 'user_b');

    expect(a.profileSelectedLocally, isTrue);
    expect(a.selectedProfileId, 'profile_a');
    expect(a.sourceSelectedLocally, isFalse);
    expect(a.selectedSourceId, isNull);

    expect(b.profileSelectedLocally, isFalse);
    expect(b.selectedProfileId, isNull);
    expect(b.sourceSelectedLocally, isTrue);
    expect(b.selectedSourceId, 'source_b');
  });
}
