import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/profile/data/repositories/fallback_profile_repository.dart';
import 'package:movi/src/core/profile/data/repositories/local_profile_repository.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test(
    'returns local profiles when no cloud session is active',
    () async {
      final harness = await _FallbackProfileRepositoryHarness.create();
      addTearDown(harness.dispose);

      final localProfile = await harness.local.createProfile(
        name: 'Offline',
        color: 0xFF2160AB,
      );

      final profiles = await harness.repository.getProfiles();

      expect(profiles, hasLength(1));
      expect(profiles.single.id, localProfile.id);
      expect(profiles.single.name, localProfile.name);
      expect(harness.remote.getProfilesCalls, 0);
    },
  );

  test(
    'loads remote profiles first after authentication even when local profiles exist',
    () async {
      final harness = await _FallbackProfileRepositoryHarness.create(
        session: const AuthSession(userId: 'cloud-user'),
        remoteProfiles: [
          const Profile(
            id: '11111111-1111-4111-8111-111111111111',
            accountId: 'cloud-user',
            name: 'Cloud A',
            color: 0xFF123456,
          ),
          const Profile(
            id: '22222222-2222-4222-8222-222222222222',
            accountId: 'cloud-user',
            name: 'Cloud B',
            color: 0xFF654321,
          ),
        ],
      );
      addTearDown(harness.dispose);

      final localProfile = await harness.local.createProfile(
        name: 'Offline',
        color: 0xFF2160AB,
      );

      final profiles = await harness.repository.getProfiles();

      expect(
        profiles.map((profile) => profile.id).toList(growable: false),
        [
          '11111111-1111-4111-8111-111111111111',
          '22222222-2222-4222-8222-222222222222',
        ],
      );
      expect(harness.remote.getProfilesCalls, 1);
      expect(harness.remote.lastAccountId, 'cloud-user');
      expect(profiles.any((profile) => profile.id == localProfile.id), isFalse);

      final persisted = await harness.local.getProfiles(accountId: 'cloud-user');
      expect(
        persisted.map((profile) => profile.id).toList(growable: false),
        [
          '11111111-1111-4111-8111-111111111111',
          '22222222-2222-4222-8222-222222222222',
        ],
      );
    },
  );

  test(
    'falls back to local profiles when remote loading fails after authentication',
    () async {
      final harness = await _FallbackProfileRepositoryHarness.create(
        session: const AuthSession(userId: 'cloud-user'),
        remoteShouldThrow: true,
      );
      addTearDown(harness.dispose);

      final localProfile = await harness.local.createProfile(
        name: 'Offline',
        color: 0xFF2160AB,
      );

      final profiles = await harness.repository.getProfiles();

      expect(profiles, hasLength(1));
      expect(profiles.single.id, localProfile.id);
      expect(profiles.single.name, localProfile.name);
      expect(harness.remote.getProfilesCalls, 1);
      expect(harness.remote.lastAccountId, 'cloud-user');
    },
  );
}

class _FallbackProfileRepositoryHarness {
  _FallbackProfileRepositoryHarness._({
    required this.db,
    required this.local,
    required this.remote,
    required this.repository,
  });

  final Database db;
  final LocalProfileRepository local;
  final _FakeRemoteProfileRepository remote;
  final FallbackProfileRepository repository;

  static Future<_FallbackProfileRepositoryHarness> create({
    AuthSession? session,
    List<Profile> remoteProfiles = const [],
    bool remoteShouldThrow = false,
  }) async {
    final db = await openDatabase(inMemoryDatabasePath, version: 1);
    final local = LocalProfileRepository(db);
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
      )
    ''');

    final auth = _FakeAuthRepository(session: session);
    final remote = _FakeRemoteProfileRepository(
      profiles: remoteProfiles,
      shouldThrow: remoteShouldThrow,
    );

    final repository = FallbackProfileRepository(
      local: local,
      auth: auth,
      remote: remote,
    );

    return _FallbackProfileRepositoryHarness._(
      db: db,
      local: local,
      remote: remote,
      repository: repository,
    );
  }

  Future<void> dispose() async {
    await db.close();
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AuthSession? session}) : _session = session;

  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();
  AuthSession? _session;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _controller.stream;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(AuthSnapshot.unauthenticated);
  }

  @override
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) {
    throw UnimplementedError();
  }
}

class _FakeRemoteProfileRepository implements ProfileRepository {
  _FakeRemoteProfileRepository({
    required List<Profile> profiles,
    this.shouldThrow = false,
  }) : _profiles = List<Profile>.from(profiles);

  final List<Profile> _profiles;
  final bool shouldThrow;

  int getProfilesCalls = 0;
  String? lastAccountId;

  @override
  Future<List<Profile>> getProfiles({
    String? accountId,
    bool? diagnostics,
  }) async {
    getProfilesCalls += 1;
    lastAccountId = accountId;
    if (shouldThrow) {
      throw StateError('remote failure');
    }
    return List<Profile>.unmodifiable(_profiles);
  }

  @override
  Future<Profile> createProfile({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfile(String profileId, {bool? diagnostics}) {
    throw UnimplementedError();
  }

  @override
  Future<Profile> getOrCreateDefaultProfile({
    String? accountId,
    bool? diagnostics,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Profile> updateProfile({
    required String profileId,
    String? name,
    int? color,
    String? avatarUrl,
    bool? isKid,
    Object? pegiLimit = ProfileRepository.noChange,
    bool? diagnostics,
  }) {
    throw UnimplementedError();
  }
}
