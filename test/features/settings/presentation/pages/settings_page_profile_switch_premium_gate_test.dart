import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
import 'package:movi/src/features/player/domain/value_objects/video_fit_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'Non-premium: tapping another profile shows premium sheet and does not switch',
    (tester) async {
      _registerSettingsPreferences();

      final fakeProfiles = _RecordingProfilesController(
        profiles: const [
          Profile(id: 'p1', accountId: 'a', name: 'Alice', color: 0xFF2160AB),
          Profile(id: 'p2', accountId: 'a', name: 'Bob', color: 0xFF2160AB),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          profilesControllerProvider.overrideWith(() => fakeProfiles),
          selectedProfileIdProvider.overrideWithValue('p1'),
          canAccessPremiumFeatureProvider.overrideWith(
            (ref, feature) async => false,
          ),
          libraryCloudSyncControllerProvider.overrideWith(
            () => _FakeLibraryCloudSyncController(),
          ),
          authControllerProvider.overrideWith(() => _FakeAuthController()),
          supabaseClientProvider.overrideWithValue(null),
          allIptvAccountsProvider.overrideWith(
            (ref) async => const <AnyIptvAccount>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      final localizer = MoviPremiumLocalizer.fromBuildContext(
        tester.element(find.byType(SettingsPage)),
      );
      expect(find.text(localizer.contextualUpsellTitle), findsOneWidget);
      expect(fakeProfiles.selectedIds, isEmpty);
    },
  );

  testWidgets('Premium: tapping another profile switches selection', (
    tester,
  ) async {
    _registerSettingsPreferences();

    final fakeProfiles = _RecordingProfilesController(
      profiles: const [
        Profile(id: 'p1', accountId: 'a', name: 'Alice', color: 0xFF2160AB),
        Profile(id: 'p2', accountId: 'a', name: 'Bob', color: 0xFF2160AB),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        profilesControllerProvider.overrideWith(() => fakeProfiles),
        selectedProfileIdProvider.overrideWithValue('p1'),
        canAccessPremiumFeatureProvider.overrideWith(
          (ref, feature) async => true,
        ),
        libraryCloudSyncControllerProvider.overrideWith(
          () => _FakeLibraryCloudSyncController(),
        ),
        authControllerProvider.overrideWith(() => _FakeAuthController()),
        supabaseClientProvider.overrideWithValue(null),
        allIptvAccountsProvider.overrideWith(
          (ref) async => const <AnyIptvAccount>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(fakeProfiles.selectedIds, ['p2']);
    expect(find.text('Bob'), findsWidgets);
  });

  testWidgets('Keyboard focus graph supports profiles and premium boundary', (
    tester,
  ) async {
    _registerSettingsPreferences();
    tester.view.physicalSize = const Size(2401, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeProfiles = _RecordingProfilesController(
      profiles: const [
        Profile(id: 'p1', accountId: 'a', name: 'Alice', color: 0xFF2160AB),
        Profile(id: 'p2', accountId: 'a', name: 'Bob', color: 0xFF2160AB),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        profilesControllerProvider.overrideWith(() => fakeProfiles),
        selectedProfileIdProvider.overrideWithValue('p1'),
        canAccessPremiumFeatureProvider.overrideWith(
          (ref, feature) async => true,
        ),
        libraryCloudSyncControllerProvider.overrideWith(
          () => _FakeLibraryCloudSyncController(),
        ),
        authControllerProvider.overrideWith(() => _FakeAuthController()),
        supabaseClientProvider.overrideWithValue(null),
        allIptvAccountsProvider.overrideWith(
          (ref) async => const <AnyIptvAccount>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstProfileAction = tester.widget<MoviFocusableAction>(
      find.byWidgetPredicate(
        (widget) =>
            widget is MoviFocusableAction &&
            widget.focusNode?.debugLabel == 'SettingsFirstProfile',
      ),
    );
    firstProfileAction.focusNode!.requestFocus();
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('SettingsFirstProfile'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('SettingsProfile-1'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('SettingsAddProfile'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('SettingsAddProfile'),
    );

    final premiumInkWell = tester.widget<InkWell>(
      find.byWidgetPredicate(
        (widget) =>
            widget is InkWell &&
            widget.focusNode?.debugLabel == 'SettingsPremiumTile',
      ),
    );
    premiumInkWell.focusNode!.requestFocus();
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('SettingsPremiumTile'),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('SettingsFirstProfile'),
    );
  });
}

void _registerSettingsPreferences() {
  sl.registerSingleton<LocalePreferences>(_MemoryLocalePreferences());
  sl.registerSingleton<IptvSyncPreferences>(_MemoryIptvSyncPreferences());
  sl.registerSingleton<AccentColorPreferences>(_MemoryAccentColorPreferences());
  sl.registerSingleton<PlayerPreferences>(
    _MemoryPlayerPreferences(
      preferredAudioLanguage: 'fr',
      preferredSubtitleLanguage: 'en',
      preferredPlaybackQuality: PreferredPlaybackQuality.fullHd,
    ),
  );
  sl.registerSingleton<SelectedIptvSourcePreferences>(
    _MemorySelectedIptvSourcePreferences(selectedSourceId: 'source-b'),
  );
}

class _RecordingProfilesController extends ProfilesController {
  _RecordingProfilesController({required this.profiles});

  final List<Profile> profiles;
  final List<String> selectedIds = <String>[];

  @override
  Future<List<Profile>> build() async => profiles;

  @override
  Future<void> selectProfile(String profileId) async {
    selectedIds.add(profileId);
  }
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
    required this.preferredAudioLanguage,
    required this.preferredSubtitleLanguage,
    required this.preferredPlaybackQuality,
  });

  final StreamController<String?> _audioController =
      StreamController<String?>.broadcast();
  final StreamController<String?> _subtitleController =
      StreamController<String?>.broadcast();
  final StreamController<PreferredPlaybackQuality?> _qualityController =
      StreamController<PreferredPlaybackQuality?>.broadcast();
  final StreamController<String?> _videoFitModeController =
      StreamController<String?>.broadcast();

  @override
  String? preferredAudioLanguage;

  @override
  String? preferredSubtitleLanguage;

  @override
  PreferredPlaybackQuality? preferredPlaybackQuality;

  @override
  VideoFitMode? preferredVideoFitMode = VideoFitMode.contain;

  @override
  Stream<String?> get preferredAudioLanguageStream => _audioController.stream;

  @override
  Stream<String?> get preferredSubtitleLanguageStream =>
      _subtitleController.stream;

  @override
  Stream<PreferredPlaybackQuality?> get preferredPlaybackQualityStream =>
      _qualityController.stream;

  @override
  Stream<String?> get preferredAudioLanguageStreamWithInitial async* {
    yield preferredAudioLanguage;
    yield* _audioController.stream;
  }

  @override
  Stream<String?> get preferredSubtitleLanguageStreamWithInitial async* {
    yield preferredSubtitleLanguage;
    yield* _subtitleController.stream;
  }

  @override
  Stream<PreferredPlaybackQuality?>
  get preferredPlaybackQualityStreamWithInitial async* {
    yield preferredPlaybackQuality;
    yield* _qualityController.stream;
  }

  @override
  Stream<String?> get preferredVideoFitModeStream =>
      _videoFitModeController.stream;

  @override
  Stream<String?> get preferredVideoFitModeStreamWithInitial async* {
    yield preferredVideoFitMode?.toValue();
    yield* _videoFitModeController.stream;
  }

  @override
  Future<void> setPreferredAudioLanguage(String? language) async {
    preferredAudioLanguage = language;
    _audioController.add(language);
  }

  @override
  Future<void> setPreferredSubtitleLanguage(String? language) async {
    preferredSubtitleLanguage = language;
    _subtitleController.add(language);
  }

  @override
  Future<void> setPreferredPlaybackQuality(
    PreferredPlaybackQuality? quality,
  ) async {
    preferredPlaybackQuality = quality;
    _qualityController.add(quality);
  }

  @override
  Future<void> setPreferredVideoFitMode(VideoFitMode? mode) async {
    preferredVideoFitMode = mode ?? VideoFitMode.contain;
    _videoFitModeController.add(preferredVideoFitMode?.toValue());
  }

  @override
  Future<void> dispose() async {
    await _audioController.close();
    await _subtitleController.close();
    await _qualityController.close();
    await _videoFitModeController.close();
  }
}

class _MemorySelectedIptvSourcePreferences
    implements SelectedIptvSourcePreferences {
  _MemorySelectedIptvSourcePreferences({required this.selectedSourceId});

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
  Future<void> setSelectedSourceId(String? id) async {
    selectedSourceId = id;
    _controller.add(id);
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
