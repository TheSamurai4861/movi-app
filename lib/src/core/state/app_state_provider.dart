import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
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
