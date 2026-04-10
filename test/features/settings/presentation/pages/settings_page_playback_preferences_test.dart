import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/controllers/profiles_controller.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'SettingsPage does not show playback preferences (feature disabled)',
    (tester) async {
      final localePreferences = _MemoryLocalePreferences();
      final syncPreferences = _MemoryIptvSyncPreferences();
      final accentColorPreferences = _MemoryAccentColorPreferences();
      final playerPreferences = _MemoryPlayerPreferences(
        preferredAudioLanguage: 'fr',
        preferredSubtitleLanguage: 'en',
        preferredPlaybackQuality: PreferredPlaybackQuality.fullHd,
      );
      final selectedSourcePreferences = _MemorySelectedIptvSourcePreferences(
        selectedSourceId: 'source-b',
      );

      sl.registerSingleton<LocalePreferences>(localePreferences);
      sl.registerSingleton<IptvSyncPreferences>(syncPreferences);
      sl.registerSingleton<AccentColorPreferences>(accentColorPreferences);
      sl.registerSingleton<PlayerPreferences>(playerPreferences);
      sl.registerSingleton<SelectedIptvSourcePreferences>(
        selectedSourcePreferences,
      );

      final container = ProviderContainer(
        overrides: [
          profilesControllerProvider.overrideWith(
            () => _FakeProfilesController(),
          ),
          selectedProfileIdProvider.overrideWithValue(null),
          libraryCloudSyncControllerProvider.overrideWith(
            () => _FakeLibraryCloudSyncController(),
          ),
          authControllerProvider.overrideWith(() => _FakeAuthController()),
          supabaseClientProvider.overrideWithValue(null),
          allIptvAccountsProvider.overrideWith(
            (ref) async => <AnyIptvAccount>[
              AnyIptvAccount.xtream(
                XtreamAccount(
                  id: 'source-a',
                  alias: 'Salon',
                  endpoint: XtreamEndpoint.parse('https://provider-a.example'),
                  username: 'demo',
                  status: XtreamAccountStatus.active,
                  createdAt: DateTime(2026, 3, 30),
                ),
              ),
              AnyIptvAccount.xtream(
                XtreamAccount(
                  id: 'source-b',
                  alias: 'Chambre',
                  endpoint: XtreamEndpoint.parse('https://provider-b.example'),
                  username: 'demo',
                  status: XtreamAccountStatus.active,
                  createdAt: DateTime(2026, 3, 30),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(selectedSourcePreferences.dispose);
      addTearDown(playerPreferences.dispose);
      addTearDown(accentColorPreferences.dispose);
      addTearDown(syncPreferences.dispose);
      addTearDown(localePreferences.dispose);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsPage()),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettingsPage)),
      )!;
      expect(find.text(l10n.settingsPlaybackSection), findsNothing);
      expect(find.text(l10n.settingsPreferredAudioLanguage), findsNothing);
      expect(find.text(l10n.settingsPreferredSubtitleLanguage), findsNothing);
      expect(find.text(l10n.settingsPreferredPlaybackQuality), findsNothing);
      expect(find.text(l10n.settingsRefreshIptvPlaylistsTitle), findsNothing);
      expect(find.text(l10n.settingsSourcesManagement), findsOneWidget);
      expect(find.text(l10n.settingsSubtitlesTitle), findsOneWidget);
      expect(find.text(l10n.settingsSyncFrequency), findsOneWidget);
    },
  );
}

class _FakeProfilesController extends ProfilesController {
  @override
  Future<List<Profile>> build() async => const <Profile>[];
}

class _FakeLibraryCloudSyncController extends LibraryCloudSyncController {
  @override
  LibraryCloudSyncState build() {
    return const LibraryCloudSyncState(autoSyncEnabled: false);
  }
}

class _FakeAuthController extends AuthController {
  @override
  AuthControllerState build() {
    return const AuthControllerState(status: AuthStatus.unauthenticated);
  }
}

class _MemoryLocalePreferences implements LocalePreferences {
  final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  String _languageCode = 'fr-FR';
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

class _MemoryIptvSyncPreferences implements IptvSyncPreferences {
  final StreamController<Duration> _controller =
      StreamController<Duration>.broadcast();

  Duration _syncInterval = const Duration(minutes: 60);

  @override
  Duration get syncInterval => _syncInterval;

  @override
  bool get isSyncDisabled => false;

  @override
  Stream<Duration> get syncIntervalStream => _controller.stream;

  @override
  Stream<Duration> get syncIntervalStreamWithInitial async* {
    yield _syncInterval;
    yield* _controller.stream;
  }

  @override
  Future<void> setSyncInterval(Duration interval) async {
    _syncInterval = interval;
    _controller.add(interval);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _MemoryAccentColorPreferences implements AccentColorPreferences {
  final StreamController<Color> _controller =
      StreamController<Color>.broadcast();

  Color _accentColor = const Color(0xFF2160AB);

  @override
  Color get accentColor => _accentColor;

  @override
  Stream<Color> get accentColorStream => _controller.stream;

  @override
  Stream<Color> get accentColorStreamWithInitial async* {
    yield _accentColor;
    yield* _controller.stream;
  }

  @override
  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    _controller.add(color);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class _MemoryPlayerPreferences implements PlayerPreferences {
  _MemoryPlayerPreferences({
    this.preferredAudioLanguage,
    this.preferredSubtitleLanguage,
    this.preferredPlaybackQuality,
  });

  final StreamController<String?> _audioController =
      StreamController<String?>.broadcast();
  final StreamController<String?> _subtitleController =
      StreamController<String?>.broadcast();
  final StreamController<PreferredPlaybackQuality?> _qualityController =
      StreamController<PreferredPlaybackQuality?>.broadcast();

  @override
  String? preferredAudioLanguage;

  @override
  String? preferredSubtitleLanguage;

  @override
  PreferredPlaybackQuality? preferredPlaybackQuality;

  @override
  Stream<String?> get preferredAudioLanguageStream => _audioController.stream;

  @override
  Stream<String?> get preferredAudioLanguageStreamWithInitial async* {
    yield preferredAudioLanguage;
    yield* _audioController.stream;
  }

  @override
  Stream<String?> get preferredSubtitleLanguageStream =>
      _subtitleController.stream;

  @override
  Stream<String?> get preferredSubtitleLanguageStreamWithInitial async* {
    yield preferredSubtitleLanguage;
    yield* _subtitleController.stream;
  }

  @override
  Stream<PreferredPlaybackQuality?> get preferredPlaybackQualityStream =>
      _qualityController.stream;

  @override
  Stream<PreferredPlaybackQuality?>
  get preferredPlaybackQualityStreamWithInitial async* {
    yield preferredPlaybackQuality;
    yield* _qualityController.stream;
  }

  @override
  Future<void> setPreferredAudioLanguage(String? code) async {
    preferredAudioLanguage = code?.trim().isEmpty == true ? null : code?.trim();
    _audioController.add(preferredAudioLanguage);
  }

  @override
  Future<void> setPreferredSubtitleLanguage(String? code) async {
    preferredSubtitleLanguage = code?.trim().isEmpty == true
        ? null
        : code?.trim();
    _subtitleController.add(preferredSubtitleLanguage);
  }

  @override
  Future<void> setPreferredPlaybackQuality(
    PreferredPlaybackQuality? quality,
  ) async {
    preferredPlaybackQuality = quality;
    _qualityController.add(preferredPlaybackQuality);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> dispose() async {
    await _audioController.close();
    await _subtitleController.close();
    await _qualityController.close();
  }
}

class _MemorySelectedIptvSourcePreferences
    implements SelectedIptvSourcePreferences {
  _MemorySelectedIptvSourcePreferences({this.selectedSourceId});

  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  @override
  String? selectedSourceId;

  @override
  Stream<String?> get selectedSourceIdStream => _controller.stream;

  @override
  Stream<String?> get selectedSourceIdStreamWithInitial async* {
    yield selectedSourceId;
    yield* _controller.stream;
  }

  @override
  Future<void> setSelectedSourceId(String? sourceId) async {
    selectedSourceId = sourceId?.trim().isEmpty == true
        ? null
        : sourceId?.trim();
    _controller.add(selectedSourceId);
  }

  @override
  Future<void> rereadFromStorage() async {}

  @override
  Future<void> clear() => setSelectedSourceId(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
