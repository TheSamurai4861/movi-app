import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/state/app_state_controller.dart';

final appStateControllerProvider = Provider<AppStateController>(
  (ref) => ref.watch(slProvider)<AppStateController>(),
);

final languageCodeStreamProvider = StreamProvider<String>((ref) {
  final prefs = ref.watch(slProvider)<LocalePreferences>();
  return prefs.languageStream;
});

Locale _parseLocale(String code) {
  final parts = code.split('-');
  final language = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'en';
  final country = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'US';
  return Locale(language, country);
}

final currentLocaleProvider = Provider<Locale>((ref) {
  final ctrl = ref.watch(appStateControllerProvider);
  final code = ref
      .watch(languageCodeStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => ctrl.preferredLocale);
  return _parseLocale(code);
});

final currentLanguageCodeProvider = Provider<String>((ref) {
  final ctrl = ref.watch(appStateControllerProvider);
  final code = ref
      .watch(languageCodeStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => ctrl.preferredLocale);
  return code;
});

final themeModeStreamProvider = StreamProvider<ThemeMode>((ref) {
  final prefs = ref.watch(slProvider)<LocalePreferences>();
  return prefs.themeStream;
});

final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  final ctrl = ref.watch(appStateControllerProvider);
  final mode = ref
      .watch(themeModeStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => ctrl.themeMode);
  return mode;
});

final iptvSyncPreferencesProvider = Provider<IptvSyncPreferences>((ref) {
  return sl<IptvSyncPreferences>();
});

final iptvSyncIntervalStreamProvider = StreamProvider<Duration>((ref) {
  final prefs = ref.watch(iptvSyncPreferencesProvider);
  return prefs.syncIntervalStream;
});

final currentIptvSyncIntervalProvider = Provider<Duration>((ref) {
  final prefs = ref.watch(iptvSyncPreferencesProvider);
  final interval = ref
      .watch(iptvSyncIntervalStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => prefs.syncInterval);
  return interval;
});

final playerPreferencesProvider = Provider<PlayerPreferences>((ref) {
  return sl<PlayerPreferences>();
});

final preferredAudioLanguageStreamProvider = StreamProvider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);
  return prefs.preferredAudioLanguageStream;
});

final currentPreferredAudioLanguageProvider = Provider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);
  final language = ref
      .watch(preferredAudioLanguageStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => prefs.preferredAudioLanguage);
  return language;
});

final preferredSubtitleLanguageStreamProvider = StreamProvider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);
  return prefs.preferredSubtitleLanguageStream;
});

final currentPreferredSubtitleLanguageProvider = Provider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);
  final language = ref
      .watch(preferredSubtitleLanguageStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => prefs.preferredSubtitleLanguage);
  return language;
});

final accentColorPreferencesProvider = Provider<AccentColorPreferences>((ref) {
  return sl<AccentColorPreferences>();
});

final accentColorStreamProvider = StreamProvider<Color>((ref) {
  final prefs = ref.watch(accentColorPreferencesProvider);
  return prefs.accentColorStream;
});

final currentAccentColorProvider = Provider<Color>((ref) {
  final prefs = ref.watch(accentColorPreferencesProvider);
  final color = ref
      .watch(accentColorStreamProvider)
      .maybeWhen(data: (value) => value, orElse: () => prefs.accentColor);
  return color;
});
