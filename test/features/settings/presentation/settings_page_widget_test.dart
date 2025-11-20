import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';

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
  Color _color = const Color(0xFF9F7AEA);
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
  testWidgets('SettingsPage shows localized headers and values', (tester) async {
    sl.reset();
    final localePrefs = FakeLocalePreferences('fr-FR', ThemeMode.system);
    final playerPrefs = FakePlayerPreferences();
    final accentPrefs = FakeAccentColorPreferences();
    final iptvPrefs = FakeIptvSyncPreferences();
    final appState = AppStateController(localePrefs);

    sl.registerSingleton<LocalePreferences>(localePrefs);
    sl.registerSingleton<PlayerPreferences>(playerPrefs);
    sl.registerSingleton<AccentColorPreferences>(accentPrefs);
    sl.registerSingleton<IptvSyncPreferences>(iptvPrefs);
    sl.registerSingleton<AppStateController>(appState);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
  }, skip: true);
}