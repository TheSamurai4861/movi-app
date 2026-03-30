import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/controllers/profiles_controller.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/features/auth/presentation/auth_otp_page.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  group('Settings reconnect validation', () {
    testWidgets('shows cloud unavailable state when backend is absent', (
      tester,
    ) async {
      final harness = _SettingsHarness.create();
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildSettingsApp());
      await tester.pumpAndSettle();

      expect(find.text('Compte cloud'), findsOneWidget);
      expect(find.text('Cloud indisponible'), findsOneWidget);
      expect(find.text('Se connecter'), findsNothing);
      expect(find.text('Déconnexion'), findsNothing);
    });

    testWidgets('shows local mode with reconnect action when backend is available but user is offline', (
      tester,
    ) async {
      final harness = _SettingsHarness.create(registerSupabaseClient: true);
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildSettingsApp());
      await tester.pumpAndSettle();

      expect(find.text('Compte cloud'), findsOneWidget);
      expect(find.text('Mode local'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
      expect(find.text('Déconnexion'), findsNothing);
    });

    testWidgets('shows connected state after cloud session is restored', (
      tester,
    ) async {
      final harness = _SettingsHarness.create(
        registerSupabaseClient: true,
        authenticated: true,
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(harness.buildSettingsApp());
      await tester.pumpAndSettle();

      expect(find.text('Compte cloud'), findsOneWidget);
      expect(find.text('Connecté'), findsOneWidget);
      expect(find.text('Déconnexion'), findsOneWidget);
      expect(find.text('Se connecter'), findsNothing);
    });
  });

  testWidgets(
    'returns to previous screen after successful OTP auth launched from settings',
    (tester) async {
      final authRepository = _FakeAuthRepository();
      sl.registerSingleton<AuthRepository>(authRepository);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/auth'),
                  child: const Text('Open auth'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, state) =>
                const AuthOtpPage(returnOnSuccess: true),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open auth'), findsOneWidget);

      await tester.tap(find.text('Open auth'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthOtpPage), findsOneWidget);

      authRepository.setAuthenticated();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Open auth'), findsOneWidget);
      expect(find.byType(AuthOtpPage), findsNothing);
    },
  );
}

class _SettingsHarness {
  _SettingsHarness._({
    required this.container,
    required this.authRepository,
    required this.cloudSyncPreferences,
  });

  final ProviderContainer container;
  final _FakeAuthRepository authRepository;
  final _MemoryCloudSyncPreferences cloudSyncPreferences;

  static _SettingsHarness create({
    bool registerSupabaseClient = false,
    bool authenticated = false,
  }) {
    final authRepository = _FakeAuthRepository(
      initialSession: authenticated
          ? const AuthSession(userId: 'cloud-user')
          : null,
    );
    final cloudSyncPreferences = _MemoryCloudSyncPreferences();

    sl.registerSingleton<AuthRepository>(authRepository);
    sl.registerSingleton<CloudSyncPreferences>(cloudSyncPreferences);

    if (registerSupabaseClient) {
      sl.registerSingleton<SupabaseClient>(
        SupabaseClient(
          'https://example.supabase.co',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
    }

    const profile = Profile(
      id: 'profile-1',
      accountId: 'local-account',
      name: 'Local profile',
      color: 0xFF2160AB,
    );

    final container = ProviderContainer(
      overrides: [
        profilesControllerProvider.overrideWith(
          () => _FakeProfilesController([profile]),
        ),
        selectedProfileIdProvider.overrideWithValue(profile.id),
        asp.currentLanguageCodeProvider.overrideWithValue('fr-FR'),
        asp.currentIptvSyncIntervalProvider.overrideWithValue(
          const Duration(minutes: 120),
        ),
        asp.currentAccentColorProvider.overrideWithValue(
          const Color(0xFF2160AB),
        ),
      ],
    );

    return _SettingsHarness._(
      container: container,
      authRepository: authRepository,
      cloudSyncPreferences: cloudSyncPreferences,
    );
  }

  Widget buildSettingsApp() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('fr', 'FR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SettingsPage()),
      ),
    );
  }

  Future<void> dispose() async {
    container.dispose();
    authRepository.dispose();
    await cloudSyncPreferences.dispose();
  }
}

class _FakeProfilesController extends ProfilesController {
  _FakeProfilesController(this._profiles);

  final List<Profile> _profiles;

  @override
  FutureOr<List<Profile>> build() => _profiles;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AuthSession? initialSession}) : _session = initialSession;

  final StreamController<AuthSnapshot> _controller =
      StreamController<AuthSnapshot>.broadcast();

  AuthSession? _session;

  @override
  Stream<AuthSnapshot> get onAuthStateChange => _controller.stream;

  @override
  AuthSession? get currentSession => _session;

  void setAuthenticated() {
    _session = const AuthSession(userId: 'cloud-user');
    _controller.add(
      AuthSnapshot(
        status: AuthStatus.authenticated,
        session: _session,
      ),
    );
  }

  void setUnauthenticated() {
    _session = null;
    _controller.add(AuthSnapshot.unauthenticated);
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    setAuthenticated();
  }

  @override
  Future<void> signInWithOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {}

  @override
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    setAuthenticated();
    return true;
  }

  @override
  Future<void> signOut() async {
    setUnauthenticated();
  }

  void dispose() {
    _controller.close();
  }
}

class _MemoryCloudSyncPreferences implements CloudSyncPreferences {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _enabled = true;

  @override
  bool get autoSyncEnabled => _enabled;

  @override
  Stream<bool> get autoSyncEnabledStream => _controller.stream;

  @override
  Stream<bool> get autoSyncEnabledStreamWithInitial async* {
    yield _enabled;
    yield* _controller.stream;
  }

  @override
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _enabled = enabled;
    _controller.add(enabled);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
