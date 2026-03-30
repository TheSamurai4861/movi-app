import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  test(
    'reconciles a selected local profile to the first cloud profile when cloud profiles are loaded',
    () async {
      final prefs = _MemorySelectedProfilePreferences();
      await prefs.setSelectedProfileId('local_profile_123');

      final harness = _ProfilesControllerHarness(
        prefs: prefs,
        repo: _FakeProfileRepository([
          const Profile(
            id: 'local_profile_123',
            accountId: 'local.default',
            name: 'Offline',
            color: 0xFF2160AB,
          ),
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
        ]),
      );
      addTearDown(harness.dispose);

      final profiles = await harness.container.read(
        profilesControllerProvider.future,
      );

      expect(profiles, hasLength(3));
      expect(prefs.selectedProfileId, '11111111-1111-4111-8111-111111111111');
    },
  );

  test(
    'selects the first cloud profile when current selection is invalid',
    () async {
      final prefs = _MemorySelectedProfilePreferences();
      await prefs.setSelectedProfileId('local_profile_missing');

      final harness = _ProfilesControllerHarness(
        prefs: prefs,
        repo: _FakeProfileRepository([
          const Profile(
            id: '22222222-2222-4222-8222-222222222222',
            accountId: 'cloud-user',
            name: 'Cloud B',
            color: 0xFF654321,
          ),
          const Profile(
            id: '11111111-1111-4111-8111-111111111111',
            accountId: 'cloud-user',
            name: 'Cloud A',
            color: 0xFF123456,
          ),
        ]),
      );
      addTearDown(harness.dispose);

      await harness.container.read(profilesControllerProvider.future);

      expect(prefs.selectedProfileId, '22222222-2222-4222-8222-222222222222');
    },
  );

  test('keeps the selected cloud profile when it is already valid', () async {
    final prefs = _MemorySelectedProfilePreferences();
    await prefs.setSelectedProfileId('22222222-2222-4222-8222-222222222222');

    final harness = _ProfilesControllerHarness(
      prefs: prefs,
      repo: _FakeProfileRepository([
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
      ]),
    );
    addTearDown(harness.dispose);

    await harness.container.read(profilesControllerProvider.future);

    expect(prefs.selectedProfileId, '22222222-2222-4222-8222-222222222222');
  });
}

class _ProfilesControllerHarness {
  _ProfilesControllerHarness({
    required this.prefs,
    required ProfileRepository repo,
  }) : localePreferences = _MemoryLocalePreferences(),
       container = ProviderContainer() {
    sl.registerSingleton<LocalePreferences>(localePreferences);
    sl.registerSingleton<SelectedProfilePreferences>(prefs);
    sl.registerSingleton<ProfileRepository>(repo);
  }

  final _MemoryLocalePreferences localePreferences;
  final _MemorySelectedProfilePreferences prefs;
  final ProviderContainer container;

  Future<void> dispose() async {
    container.dispose();
    await localePreferences.dispose();
    await prefs.dispose();
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(List<Profile> profiles)
    : _profiles = List<Profile>.from(profiles);

  final List<Profile> _profiles;

  @override
  Future<List<Profile>> getProfiles({
    String? accountId,
    bool? diagnostics,
  }) async {
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
    if (!_controller.isClosed) {
      _controller.add(_selectedProfileId);
    }
  }

  @override
  Future<void> clear() => setSelectedProfileId(null);

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
