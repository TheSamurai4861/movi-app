import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';
import 'package:movi/src/core/storage/repositories/playlist_local_repository.dart';
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';
import 'package:movi/src/core/storage/repositories/sync_outbox_repository.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';
import 'package:movi/src/features/library/application/services/comprehensive_cloud_sync_service.dart';
import 'package:movi/src/features/library/application/services/library_cloud_sync_service.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await sl.reset();
  });

  test('does not auto-sync while Supabase client is unavailable', () async {
    final harness = await _LibraryCloudSyncHarness.create();
    addTearDown(harness.dispose);

    harness.container.read(libraryCloudSyncControllerProvider);
    await harness.selectedProfilePreferences.setSelectedProfileId(
      harness.profile.id,
    );

    await harness.pumpAutoSync();

    expect(harness.syncService.syncAllCalls, 0);
    expect(harness.syncService.pullUserPreferencesCalls, 0);

    final state = harness.container.read(libraryCloudSyncControllerProvider);
    expect(state.isSyncing, isFalse);
    expect(state.lastSuccessAtUtc, isNull);
    expect(state.lastError, isNull);
  });

  test(
    'resumes auto-sync when Supabase client becomes available again',
    () async {
      final harness = await _LibraryCloudSyncHarness.create();
      addTearDown(harness.dispose);

      final events = <AppEvent>[];
      final sub = harness.container
          .read(appEventBusProvider)
          .stream
          .listen(events.add);
      addTearDown(sub.cancel);

      harness.container.read(libraryCloudSyncControllerProvider);
      await harness.selectedProfilePreferences.setSelectedProfileId(
        harness.profile.id,
      );
      await harness.pumpAutoSync();

      expect(harness.syncService.syncAllCalls, 0);

      harness.registerSupabaseClient();
      expect(harness.container.refresh(supabaseClientProvider), isNotNull);

      await harness.pumpAutoSync();

      expect(harness.syncService.syncAllCalls, 1);
      expect(harness.syncService.pullUserPreferencesCalls, 1);
      expect(harness.syncService.syncedProfileIds, [harness.profile.id]);
      expect(
        events.map((event) => event.type),
        contains(AppEventType.librarySynced),
      );

      final state = harness.container.read(libraryCloudSyncControllerProvider);
      expect(state.isSyncing, isFalse);
      expect(state.lastSuccessAtUtc, isNotNull);
      expect(state.lastError, isNull);
    },
  );

  test('does not auto-sync for a local-only selected profile id', () async {
    final harness = await _LibraryCloudSyncHarness.create(
      profileId: 'local_profile_123_456',
    );
    addTearDown(harness.dispose);

    harness.registerSupabaseClient();
    harness.container.read(libraryCloudSyncControllerProvider);
    await harness.selectedProfilePreferences.setSelectedProfileId(
      harness.profile.id,
    );

    await harness.pumpAutoSync();

    expect(harness.syncService.syncAllCalls, 0);
    expect(harness.syncService.pullUserPreferencesCalls, 0);

    final state = harness.container.read(libraryCloudSyncControllerProvider);
    expect(state.isSyncing, isFalse);
    expect(state.lastSuccessAtUtc, isNull);
    expect(state.lastError, isNull);
  });

  test(
    'manual sync reports a friendly error for a local-only selected profile id',
    () async {
      final harness = await _LibraryCloudSyncHarness.create(
        profileId: 'local_profile_123_456',
      );
      addTearDown(harness.dispose);

      harness.registerSupabaseClient();

      await harness.selectedProfilePreferences.setSelectedProfileId(
        harness.profile.id,
      );

      await harness.container
          .read(libraryCloudSyncControllerProvider.notifier)
          .syncNow();

      expect(harness.syncService.syncAllCalls, 0);
      expect(harness.syncService.pullUserPreferencesCalls, 0);

      final state = harness.container.read(libraryCloudSyncControllerProvider);
      expect(state.isSyncing, isFalse);
      expect(state.lastSuccessAtUtc, isNull);
      expect(state.lastError, 'Profil local non synchronisable.');
    },
  );
}

class _LibraryCloudSyncHarness {
  _LibraryCloudSyncHarness._({
    required this.db,
    required this.container,
    required this.profile,
    required this.syncService,
    required this.localePreferences,
    required this.selectedProfilePreferences,
    required this.cloudSyncPreferences,
  });

  final Database db;
  final ProviderContainer container;
  final Profile profile;
  final _SpyComprehensiveCloudSyncService syncService;
  final _MemoryLocalePreferences localePreferences;
  final _MemorySelectedProfilePreferences selectedProfilePreferences;
  final _MemoryCloudSyncPreferences cloudSyncPreferences;

  static Future<_LibraryCloudSyncHarness> create({
    String profileId = '11111111-1111-4111-8111-111111111111',
  }) async {
    await sl.reset();

    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 18,
      onCreate: (database, version) async {
        await LocalDatabaseSchema.create(database, version);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        await LocalDatabaseMigrations.upgrade(database, oldVersion, newVersion);
      },
    );

    final profile = Profile(
      id: profileId,
      accountId: 'local-account',
      name: 'Offline Profile',
      color: 0xFF2160AB,
    );

    final localePreferences = _MemoryLocalePreferences();
    final selectedProfilePreferences = _MemorySelectedProfilePreferences();
    final cloudSyncPreferences = _MemoryCloudSyncPreferences();
    final syncService = _SpyComprehensiveCloudSyncService(db);

    sl.registerSingleton<LocalePreferences>(localePreferences);
    sl.registerSingleton<SelectedProfilePreferences>(
      selectedProfilePreferences,
    );
    sl.registerSingleton<CloudSyncPreferences>(cloudSyncPreferences);
    sl.registerSingleton<ProfileRepository>(_FakeProfileRepository([profile]));

    final container = ProviderContainer(
      overrides: [
        comprehensiveCloudSyncServiceProvider.overrideWithValue(syncService),
      ],
    );

    return _LibraryCloudSyncHarness._(
      db: db,
      container: container,
      profile: profile,
      syncService: syncService,
      localePreferences: localePreferences,
      selectedProfilePreferences: selectedProfilePreferences,
      cloudSyncPreferences: cloudSyncPreferences,
    );
  }

  void registerSupabaseClient() {
    if (sl.isRegistered<SupabaseClient>()) return;
    sl.registerSingleton<SupabaseClient>(
      SupabaseClient('https://example.supabase.co', 'test-anon-key'),
    );
  }

  Future<void> pumpAutoSync() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
    await localePreferences.dispose();
    await selectedProfilePreferences.dispose();
    await cloudSyncPreferences.dispose();
  }
}

class _SpyComprehensiveCloudSyncService extends ComprehensiveCloudSyncService {
  _SpyComprehensiveCloudSyncService(Database db)
    : super(
        sl: sl,
        librarySync: LibraryCloudSyncService(
          secureStorage: SecureStorageRepository(),
          outbox: SyncOutboxRepository(db),
          db: db,
          playlistLocal: PlaylistLocalRepository(db: db),
        ),
      );

  int syncAllCalls = 0;
  int pullUserPreferencesCalls = 0;
  final List<String> syncedProfileIds = <String>[];

  @override
  Future<void> syncAll({
    required SupabaseClient client,
    required String profileId,
    bool Function()? shouldCancel,
  }) async {
    syncAllCalls += 1;
    syncedProfileIds.add(profileId);
  }

  @override
  Future<void> pullUserPreferences({
    required SupabaseClient client,
    bool Function()? shouldCancel,
    Set<String>? knownIptvAccountIds,
  }) async {
    pullUserPreferencesCalls += 1;
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(List<Profile> profiles)
    : _profiles = List<Profile>.from(profiles);

  final List<Profile> _profiles;

  @override
  Future<Profile> createProfile({
    required String name,
    required int color,
    String? avatarUrl,
    String? accountId,
    bool? diagnostics,
  }) async {
    final created = Profile(
      id: 'profile-${_profiles.length + 1}',
      accountId: accountId ?? 'local-account',
      name: name,
      color: color,
      avatarUrl: avatarUrl,
    );
    _profiles.add(created);
    return created;
  }

  @override
  Future<void> deleteProfile(String profileId, {bool? diagnostics}) async {
    _profiles.removeWhere((profile) => profile.id == profileId);
  }

  @override
  Future<Profile> getOrCreateDefaultProfile({
    String? accountId,
    bool? diagnostics,
  }) async {
    if (_profiles.isNotEmpty) return _profiles.first;
    return createProfile(
      name: 'Default',
      color: 0xFF2160AB,
      accountId: accountId,
      diagnostics: diagnostics,
    );
  }

  @override
  Future<List<Profile>> getProfiles({
    String? accountId,
    bool? diagnostics,
  }) async {
    return List<Profile>.unmodifiable(_profiles);
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
  }) async {
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) {
      throw StateError('Profile not found: $profileId');
    }

    final current = _profiles[index];
    final updated = current.copyWith(
      name: name,
      color: color,
      avatarUrl: avatarUrl,
      isKid: isKid,
      pegiLimit: identical(pegiLimit, ProfileRepository.noChange)
          ? current.pegiLimit
          : pegiLimit as int?,
    );

    _profiles[index] = updated;
    return updated;
  }
}

class _MemoryCloudSyncPreferences implements CloudSyncPreferences {
  _MemoryCloudSyncPreferences({bool autoSyncEnabled = true})
    : _autoSyncEnabled = autoSyncEnabled;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _autoSyncEnabled;

  @override
  bool get autoSyncEnabled => _autoSyncEnabled;

  @override
  bool get userWantsAutoSync => autoSyncEnabled;

  @override
  Stream<bool> get autoSyncEnabledStream => _controller.stream;

  @override
  Stream<bool> get userWantsAutoSyncStream => autoSyncEnabledStream;

  @override
  Stream<bool> get autoSyncEnabledStreamWithInitial async* {
    yield _autoSyncEnabled;
    yield* _controller.stream;
  }

  @override
  Stream<bool> get userWantsAutoSyncStreamWithInitial =>
      autoSyncEnabledStreamWithInitial;

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async {
    if (enabled == _autoSyncEnabled) return;
    _autoSyncEnabled = enabled;
    if (!_controller.isClosed) {
      _controller.add(enabled);
    }
  }

  @override
  Future<void> setUserWantsAutoSync(bool enabled) {
    return setAutoSyncEnabled(enabled);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _MemoryLocalePreferences implements LocalePreferences {
  final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  String _languageCode = 'en-US';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  String get languageCode => _languageCode;

  @override
  Stream<String> get languageStream => _languageController.stream;

  @override
  Stream<String> get languageStreamWithInitial async* {
    yield _languageCode;
    yield* _languageController.stream;
  }

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;

  @override
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield _themeMode;
    yield* _themeController.stream;
  }

  @override
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    _languageController.add(code);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _themeController.add(mode);
  }

  @override
  Future<void> dispose() async {
    await _languageController.close();
    await _themeController.close();
  }
}

class _MemorySelectedProfilePreferences implements SelectedProfilePreferences {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  String? _selectedProfileId;

  @override
  String? get selectedProfileId => _selectedProfileId;

  @override
  Stream<String?> get selectedProfileIdStream => _controller.stream;

  @override
  Stream<String?> get selectedProfileIdStreamWithInitial async* {
    yield _selectedProfileId;
    yield* _controller.stream;
  }

  @override
  Future<void> setSelectedProfileId(String? profileId) async {
    _selectedProfileId = profileId?.trim().isEmpty == true
        ? null
        : profileId?.trim();
    _controller.add(_selectedProfileId);
  }

  @override
  Future<void> clear() => setSelectedProfileId(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}