import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';

void main() {
  group('SubtitleAppearancePreferences', () {
    test('returns defaults when no value exists', () async {
      final storage = _MemorySecureStorage();
      final prefs = await SubtitleAppearancePreferences.create(
        storage: storage,
      );

      final value = await prefs.getForProfile('profile-a');
      expect(value, SubtitleAppearancePrefs.defaults);
    });

    test('stores values per profile', () async {
      final storage = _MemorySecureStorage();
      final prefs = await SubtitleAppearancePreferences.create(
        storage: storage,
      );

      await prefs.setForProfile(
        'profile-a',
        const SubtitleAppearancePrefs(
          sizePreset: SubtitleSizePreset.large,
          textColorHex: '#FFFFEB3B',
          fontFamilyKey: 'roboto',
          backgroundColorHex: '#FF000000',
          backgroundOpacity: 0.66,
          shadowPreset: SubtitleShadowPreset.soft,
          fontScale: 1.15,
        ),
      );
      await prefs.setForProfile(
        'profile-b',
        const SubtitleAppearancePrefs(
          sizePreset: SubtitleSizePreset.small,
          textColorHex: '#FF80DEEA',
          fontFamilyKey: 'system',
          backgroundColorHex: '#FF1E1E1E',
          backgroundOpacity: 0.5,
          shadowPreset: SubtitleShadowPreset.off,
          fontScale: 0.95,
        ),
      );

      final a = await prefs.getForProfile('profile-a');
      final b = await prefs.getForProfile('profile-b');
      expect(a.sizePreset, SubtitleSizePreset.large);
      expect(a.textColorHex, '#FFFFEB3B');
      expect(a.shadowPreset, SubtitleShadowPreset.soft);
      expect(b.sizePreset, SubtitleSizePreset.small);
      expect(b.textColorHex, '#FF80DEEA');
      expect(b.backgroundOpacity, 0.5);
    });

    test('watchForProfile emits only scoped updates', () async {
      final storage = _MemorySecureStorage();
      final prefs = await SubtitleAppearancePreferences.create(
        storage: storage,
      );
      final events = <SubtitleAppearancePrefs>[];
      final done = Completer<void>();

      final sub = prefs.watchForProfile('profile-a').listen((event) {
        events.add(event);
        if (events.length == 2 && !done.isCompleted) {
          done.complete();
        }
      });

      await prefs.setForProfile(
        'profile-b',
        const SubtitleAppearancePrefs(
          sizePreset: SubtitleSizePreset.large,
          textColorHex: '#FFA5D6A7',
          fontFamilyKey: 'arial',
          backgroundColorHex: '#FF000000',
          backgroundOpacity: 0.66,
          shadowPreset: SubtitleShadowPreset.strong,
          fontScale: 1.2,
        ),
      );
      await prefs.setForProfile(
        'profile-a',
        const SubtitleAppearancePrefs(
          sizePreset: SubtitleSizePreset.small,
          textColorHex: '#FFFFFFFF',
          fontFamilyKey: 'system',
          backgroundColorHex: '#FF000000',
          backgroundOpacity: 0.66,
          shadowPreset: SubtitleShadowPreset.off,
          fontScale: 1.0,
        ),
      );

      await done.future.timeout(const Duration(seconds: 2));
      expect(events.first, SubtitleAppearancePrefs.defaults);
      expect(events.last.sizePreset, SubtitleSizePreset.small);
      await sub.cancel();
    });

    test('migrates legacy payload with safe defaults', () {
      final decoded = SubtitleAppearancePrefs.fromJson(<String, Object?>{
        'sizePreset': 'medium',
        'textColorHex': '#FFFFFFFF',
        'fontFamilyKey': 'system',
      });
      expect(
        decoded.backgroundColorHex,
        SubtitleAppearancePrefs.defaultBackgroundColorHex,
      );
      expect(
        decoded.backgroundOpacity,
        SubtitleAppearancePrefs.defaultBackgroundOpacity,
      );
      expect(decoded.shadowPreset, SubtitleShadowPreset.off);
      expect(decoded.fontScale, 1.0);
    });

    test('clamps invalid fontScale and backgroundOpacity', () {
      final decoded = SubtitleAppearancePrefs.fromJson(<String, Object?>{
        'sizePreset': 'large',
        'textColorHex': '#FFFFFFFF',
        'fontFamilyKey': 'system',
        'backgroundColorHex': '#FF000000',
        'backgroundOpacity': 2.4,
        'shadowPreset': 'strong',
        'fontScale': -10,
      });
      expect(decoded.backgroundOpacity, 1.0);
      expect(decoded.fontScale, SubtitleAppearancePrefs.minFontScale);
      expect(decoded.shadowPreset, SubtitleShadowPreset.strong);
    });
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage();

  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
      return;
    }
    _values[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
  }) async {
    return _values[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
  }) async {
    _values.remove(key);
  }
}
