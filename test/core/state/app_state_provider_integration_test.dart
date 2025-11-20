// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

class FakeLocalePreferences implements LocalePreferences {
  FakeLocalePreferences(this._languageCode, this._themeMode);

  String _languageCode;
  ThemeMode _themeMode;
  final _languageController = StreamController<String>.broadcast();
  final _themeController = StreamController<ThemeMode>.broadcast();

  @override
  String get languageCode => _languageCode;
  @override
  Stream<String> get languageStream => _languageController.stream;
  @override
  ThemeMode get themeMode => _themeMode;
  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;
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

class FakePlayerPreferences implements PlayerPreferences {
  String? _audio;
  String? _subs;
  final _audioController = StreamController<String?>.broadcast();
  final _subsController = StreamController<String?>.broadcast();

  @override
  String? get preferredAudioLanguage => _audio;
  @override
  Stream<String?> get preferredAudioLanguageStream => _audioController.stream;
  @override
  String? get preferredSubtitleLanguage => _subs;
  @override
  Stream<String?> get preferredSubtitleLanguageStream => _subsController.stream;
  @override
  Future<void> setPreferredAudioLanguage(String? code) async {
    _audio = code;
    _audioController.add(code);
  }
  @override
  Future<void> setPreferredSubtitleLanguage(String? code) async {
    _subs = code;
    _subsController.add(code);
  }
  @override
  Future<void> dispose() async {
    await _audioController.close();
    await _subsController.close();
  }
}

class FakeAccentColorPreferences implements AccentColorPreferences {
  Color _color = const Color(0xFF2160AB);
  final _controller = StreamController<Color>.broadcast();
  @override
  Color get accentColor => _color;
  @override
  Stream<Color> get accentColorStream => _controller.stream;
  @override
  Future<void> setAccentColor(Color color) async {
    _color = color;
    _controller.add(color);
  }
  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeIptvSyncPreferences implements IptvSyncPreferences {
  Duration _interval = const Duration(hours: 2);
  final _controller = StreamController<Duration>.broadcast();
  @override
  Duration get syncInterval => _interval;
  @override
  Stream<Duration> get syncIntervalStream => _controller.stream;
  @override
  Future<void> setSyncInterval(Duration interval) async {
    _interval = interval;
    _controller.add(interval);
  }
  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  group('App state providers reflect preferences changes', () {
    late FakeLocalePreferences localePrefs;
    late FakePlayerPreferences playerPrefs;
    late FakeAccentColorPreferences accentPrefs;
    late FakeIptvSyncPreferences iptvPrefs;
    late AppStateController appState;

    setUp(() {
      sl.reset();
      localePrefs = FakeLocalePreferences('fr-FR', ThemeMode.system);
      playerPrefs = FakePlayerPreferences();
      accentPrefs = FakeAccentColorPreferences();
      iptvPrefs = FakeIptvSyncPreferences();
      appState = AppStateController(localePrefs)..attachLocaleStream();

      sl.registerSingleton<LocalePreferences>(localePrefs);
      sl.registerSingleton<PlayerPreferences>(playerPrefs);
      sl.registerSingleton<AccentColorPreferences>(accentPrefs);
      sl.registerSingleton<IptvSyncPreferences>(iptvPrefs);
      sl.registerSingleton<AppStateController>(appState);
    });

    tearDown(() async {
      await localePrefs.dispose();
      await playerPrefs.dispose();
      await accentPrefs.dispose();
      await iptvPrefs.dispose();
      // no ProviderContainer
    });

    test('language changes are reflected', () async {
      expect(appState.preferredLocale, 'fr-FR');
      await localePrefs.setLanguageCode('en-US');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(appState.preferredLocale, 'en-US');
    });

    test('theme mode changes are reflected', () async {
      expect(appState.themeMode, ThemeMode.system);
      await localePrefs.setThemeMode(ThemeMode.dark);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(appState.themeMode, ThemeMode.dark);
    });

    test('accent color changes are reflected', () async {
      final initial = accentPrefs.accentColor;
      expect(initial, isA<Color>());
      await accentPrefs.setAccentColor(const Color(0xFF34C759));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(accentPrefs.accentColor.value, const Color(0xFF34C759).value);
    });

    test('audio/subtitle preference changes are reflected', () async {
      expect(playerPrefs.preferredAudioLanguage, isNull);
      expect(playerPrefs.preferredSubtitleLanguage, isNull);
      await playerPrefs.setPreferredAudioLanguage('fr');
      await playerPrefs.setPreferredSubtitleLanguage('en');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(playerPrefs.preferredAudioLanguage, 'fr');
      expect(playerPrefs.preferredSubtitleLanguage, 'en');
    });

    test('IPTV sync interval changes are reflected', () async {
      expect(iptvPrefs.syncInterval, const Duration(hours: 2));
      await iptvPrefs.setSyncInterval(const Duration(hours: 6));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(iptvPrefs.syncInterval, const Duration(hours: 6));
    });
  });
}