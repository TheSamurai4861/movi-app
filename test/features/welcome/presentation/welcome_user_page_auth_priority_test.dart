import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_auth_providers.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_user_page.dart';
import 'package:movi/src/core/profile/presentation/controllers/profiles_controller.dart';
import 'package:movi/src/core/profile/presentation/controllers/selected_profile_controller.dart';

class _FakeSupabaseAuthStatusNotifier extends SupabaseAuthStatusNotifier {
  _FakeSupabaseAuthStatusNotifier(this._value);
  final SupabaseAuthStatus _value;

  @override
  SupabaseAuthStatus build() => _value;
}

class _FakeUserSettingsController extends UserSettingsController {
  @override
  UserSettingsState build() => const UserSettingsState();

  @override
  Future<void> load() async {}

  @override
  Future<bool> save(UserSettings profile) async => true;
}

class _FakeProfilesController extends ProfilesController {
  @override
  Future<List<Profile>> build() async => <Profile>[];
}

class _FakeSelectedProfileController extends SelectedProfileController {
  @override
  String? build() => null;
}

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('OTP_PAGE')),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  testWidgets(
    'Supabase dispo + unauthenticated => ouvre automatiquement OTP en priorité',
    (tester) async {
      final client = SupabaseClient('https://example.supabase.co', 'anon-key');
      // Empêche le timer d'auto-refresh (sinon flutter_test détecte un timer pending).
      client.auth.stopAutoRefresh();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(client),
            supabaseAuthStatusProvider.overrideWith(
              () => _FakeSupabaseAuthStatusNotifier(
                SupabaseAuthStatus.unauthenticated,
              ),
            ),
            userSettingsControllerProvider.overrideWith(
              _FakeUserSettingsController.new,
            ),
            profilesControllerProvider.overrideWith(_FakeProfilesController.new),
            selectedProfileControllerProvider.overrideWith(
              _FakeSelectedProfileController.new,
            ),
          ],
          child: _wrapWithRouter(const WelcomeUserPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OTP_PAGE'), findsOneWidget);
    },
  );

  testWidgets(
    'Supabase indispo (client null) => propose local (pseudo) comme avant',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseClientProvider.overrideWithValue(null),
            supabaseAuthStatusProvider.overrideWith(
              () => _FakeSupabaseAuthStatusNotifier(
                SupabaseAuthStatus.uninitialized,
              ),
            ),
            userSettingsControllerProvider.overrideWith(
              _FakeUserSettingsController.new,
            ),
            profilesControllerProvider.overrideWith(_FakeProfilesController.new),
            selectedProfileControllerProvider.overrideWith(
              _FakeSelectedProfileController.new,
            ),
          ],
          child: _wrapWithRouter(const WelcomeUserPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Mode local: champ pseudo affiché (TextFormField présent)
      expect(find.byType(TextFormField), findsOneWidget);
    },
  );
}

