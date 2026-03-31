import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/data/repositories/fallback_profile_repository.dart';
import 'package:movi/src/core/profile/data/repositories/local_profile_repository.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/database/sqlite_database_migrations.dart';
import 'package:movi/src/core/storage/database/sqlite_database_schema.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/utils/result.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_catalog_snapshot.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/repositories/iptv_repository.dart';
import 'package:movi/src/features/iptv/domain/repositories/stalker_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await sl.reset();
  });

  test(
    'returns welcomeUser without backend when no local profile exists',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.welcomeUser);
      expect(result.meta.accountId, isNull);
      expect(result.meta.profilesCount, 0);
    },
  );

  test(
    'returns welcomeSources without backend when local profile exists but no local source exists',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      final created = await harness.localProfiles.createProfile(
        name: 'Local Profile',
        color: 0xFF2160AB,
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.welcomeSources);
      expect(result.meta.profilesCount, 1);
      expect(harness.selectedProfilePreferences.selectedProfileId, created.id);
    },
  );

  test(
    'returns home without backend when local profile and local IPTV source exist',
    () async {
      final harness = await _LaunchHarness.create();
      addTearDown(harness.dispose);

      final created = await harness.localProfiles.createProfile(
        name: 'Offline Profile',
        color: 0xFF2160AB,
      );
      const accountId = 'local_xtream_account';
      await harness.iptvLocal.saveAccount(
        XtreamAccount(
          id: accountId,
          alias: 'Offline Source',
          endpoint: XtreamEndpoint.parse('http://example.com'),
          username: 'demo',
          status: XtreamAccountStatus.pending,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await harness.run();

      expect(result.isSuccess, isTrue);
      expect(result.destination, BootstrapDestination.home);
      expect(result.meta.profilesCount, 1);
      expect(result.meta.localAccountsCount, 1);
      expect(result.meta.selectedProfileId, created.id);
      expect(result.meta.selectedSourceId, accountId);
      expect(harness.selectedProfilePreferences.selectedProfileId, created.id);
      expect(harness.selectedSourcePreferences.selectedSourceId, accountId);
      expect(harness.homeController.loadCalls, 1);
      // Bootstrap progress stage should be cleared after preload.
      expect(
        harness.container.read(homeBootstrapProgressStageProvider),
        isNull,
      );
      expect(
        harness.container.read(appStateControllerProvider).activeIptvSourceIds,
        {accountId},
      );
    },
  );
}

class _LaunchHarness {
  _LaunchHarness._({
    required this.db,
    required this.container,
    required this.localProfiles,
    required this.iptvLocal,
    required this.selectedProfilePreferences,
    required this.selectedSourcePreferences,
    required this.localePreferences,
    required this.authRepository,
    required this.homeController,
  });

  final Database db;
  final ProviderContainer container;
  final LocalProfileRepository localProfiles;
  final IptvLocalRepository iptvLocal;
  final _MemorySelectedProfilePreferences selectedProfilePreferences;
  final _MemorySelectedIptvSourcePreferences selectedSourcePreferences;
  final _MemoryLocalePreferences localePreferences;
  final _FakeAuthRepository authRepository;
  final _FakeHomeController homeController;

  static Future<_LaunchHarness> create() async {
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

    final localePreferences = _MemoryLocalePreferences();
    final selectedProfilePreferences = _MemorySelectedProfilePreferences();
    final selectedSourcePreferences = _MemorySelectedIptvSourcePreferences();
    final authRepository = _FakeAuthRepository();
    final localProfiles = LocalProfileRepository(db);
    final iptvLocal = IptvLocalRepository(db);
    final contentCache = ContentCacheRepository(db);
    final logger = _MemoryLogger();
    final refreshXtreamCatalog = _FakeRefreshXtreamCatalog();
    final refreshStalkerCatalog = _FakeRefreshStalkerCatalog();
    final homeController = _FakeHomeController();

    sl.registerSingleton<Database>(db);
    sl.registerSingleton<AppLogger>(logger);
    sl.registerSingleton<LocalePreferences>(localePreferences);
    sl.registerSingleton<SelectedProfilePreferences>(
      selectedProfilePreferences,
    );
    sl.registerSingleton<SelectedIptvSourcePreferences>(
      selectedSourcePreferences,
    );
    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<LocalProfileRepository>(localProfiles);
    sl.registerSingleton<ProfileRepository>(
      FallbackProfileRepository(local: localProfiles, auth: authRepository),
    );
    sl.registerSingleton<IptvLocalRepository>(iptvLocal);
    sl.registerSingleton<AppLaunchStateRegistry>(AppLaunchStateRegistry());
    sl.registerSingleton<RefreshXtreamCatalog>(refreshXtreamCatalog);
    sl.registerSingleton<RefreshStalkerCatalog>(refreshStalkerCatalog);

    final container = ProviderContainer(
      overrides: [
        app_startup_provider.appStartupProvider.overrideWith((ref) async {}),
        homeControllerProvider.overrideWith(() => homeController),
      ],
    );

    final appStateController = container.read(appStateControllerProvider);
    sl.registerSingleton<XtreamSyncService>(
      _NoopXtreamSyncService(
        appStateController,
        refreshXtreamCatalog,
        XtreamCacheDataSource(contentCache),
        logger,
      ),
    );

    return _LaunchHarness._(
      db: db,
      container: container,
      localProfiles: localProfiles,
      iptvLocal: iptvLocal,
      selectedProfilePreferences: selectedProfilePreferences,
      selectedSourcePreferences: selectedSourcePreferences,
      localePreferences: localePreferences,
      authRepository: authRepository,
      homeController: homeController,
    );
  }

  Future<AppLaunchResult> run() {
    return container.read(appLaunchOrchestratorProvider.notifier).run();
  }

  Future<void> dispose() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    container.dispose();
    await db.close();
    await localePreferences.dispose();
    await selectedProfilePreferences.dispose();
    await selectedSourcePreferences.dispose();
    authRepository.dispose();
  }
}

class _FakeHomeController extends HomeController {
  int loadCalls = 0;

  @override
  HomeState build() => const HomeState();

  @override
  Future<void> load({
    bool awaitIptv = false,
    String reason = 'unknown',
    bool force = false,
    Duration? cooldown,
  }) async {
    loadCalls += 1;
  }
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();

  AuthSession? _session;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _controller.stream;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _session = const AuthSession(userId: 'test-user');
    _controller.add(
      AuthSnapshot(status: AuthStatus.authenticated, session: _session),
    );
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {}

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    _session = const AuthSession(userId: 'test-user');
    _controller.add(
      AuthSnapshot(status: AuthStatus.authenticated, session: _session),
    );
    return true;
  }

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(AuthSnapshot.unauthenticated);
  }

  void dispose() {
    _controller.close();
  }
}

class _MemoryLogger implements AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void debug(String message, {String? category}) {
    log(LogLevel.debug, message, category: category);
  }

  @override
  void info(String message, {String? category}) {
    log(LogLevel.info, message, category: category);
  }

  @override
  void warn(String message, {String? category}) {
    log(LogLevel.warn, message, category: category);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime.now(),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
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

class _MemorySelectedIptvSourcePreferences
    implements SelectedIptvSourcePreferences {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  String? _selectedSourceId;

  @override
  String? get selectedSourceId => _selectedSourceId;

  @override
  Stream<String?> get selectedSourceIdStream => _controller.stream;

  @override
  Stream<String?> get selectedSourceIdStreamWithInitial async* {
    yield _selectedSourceId;
    yield* _controller.stream;
  }

  @override
  Future<void> setSelectedSourceId(String? sourceId) async {
    _selectedSourceId = sourceId?.trim().isEmpty == true
        ? null
        : sourceId?.trim();
    _controller.add(_selectedSourceId);
  }

  @override
  Future<void> clear() => setSelectedSourceId(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeRefreshXtreamCatalog extends RefreshXtreamCatalog {
  _FakeRefreshXtreamCatalog() : super(_FakeIptvRepository());

  @override
  Future<Result<XtreamCatalogSnapshot, Failure>> call(String accountId) async {
    return Ok(
      XtreamCatalogSnapshot(
        accountId: accountId,
        lastSyncAt: DateTime.now(),
        movieCount: 0,
        seriesCount: 0,
      ),
    );
  }
}

class _FakeRefreshStalkerCatalog extends RefreshStalkerCatalog {
  _FakeRefreshStalkerCatalog() : super(_FakeStalkerRepository());

  @override
  Future<Result<StalkerCatalogSnapshot, Failure>> call(String accountId) async {
    return Ok(
      StalkerCatalogSnapshot(
        accountId: accountId,
        lastSyncAt: DateTime.now(),
        movieCount: 0,
        seriesCount: 0,
      ),
    );
  }
}

class _NoopXtreamSyncService extends XtreamSyncService {
  _NoopXtreamSyncService(super.state, super.refresh, super.cache, super.logger);

  @override
  void start({
    bool skipInitialIfFresh = true,
    DateTime? initialRefreshAt,
    Duration? initialCooldown,
    String reason = 'service',
  }) {}

  @override
  void stop() {}
}

class _FakeIptvRepository implements IptvRepository {
  @override
  Future<XtreamAccount> addSource({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String alias,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) async {
    return const <XtreamPlaylist>[];
  }

  @override
  Future<XtreamCatalogSnapshot> refreshCatalog(String accountId) async {
    return XtreamCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: 0,
      seriesCount: 0,
    );
  }
}

class _FakeStalkerRepository implements StalkerRepository {
  @override
  Future<StalkerAccount> addSource({
    required StalkerEndpoint endpoint,
    required String macAddress,
    String? username,
    String? password,
    required String alias,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<XtreamPlaylist>> listPlaylists(String accountId) async {
    return const <XtreamPlaylist>[];
  }

  @override
  Future<StalkerCatalogSnapshot> refreshCatalog(String accountId) async {
    return StalkerCatalogSnapshot(
      accountId: accountId,
      lastSyncAt: DateTime.now(),
      movieCount: 0,
      seriesCount: 0,
    );
  }
}
