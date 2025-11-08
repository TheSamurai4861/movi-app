import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'app_state.dart';

import '../preferences/locale_preferences.dart';

class AppStateController extends StateNotifier<AppState> {
  AppStateController(this._localePreferences)
      : super(AppState(preferredLocale: _localePreferences.languageCode));

  final LocalePreferences _localePreferences;

  // Safe read-only accessors for external services (avoid using protected `state`)
  List<String> get activeIptvSourceIds => List.unmodifiable(state.activeIptvSources);
  bool get hasActiveIptvSources => state.activeIptvSources.isNotEmpty;

  void setThemeMode(ThemeMode mode) {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
  }

  void setConnectivity(bool isOnline) {
    if (state.isOnline == isOnline) return;
    state = state.copyWith(isOnline: isOnline);
  }

  void setActiveIptvSources(List<String> sources) {
    state = state.copyWith(activeIptvSources: List.unmodifiable(sources));
  }

  Future<void> setPreferredLocale(String locale) async {
    if (state.preferredLocale == locale) return;
    await _localePreferences.setLanguageCode(locale);
    state = state.copyWith(preferredLocale: locale);
  }

  void addIptvSource(String accountId) {
    if (state.activeIptvSources.contains(accountId)) return;
    final updated = [...state.activeIptvSources, accountId];
    setActiveIptvSources(updated);
  }

  void removeIptvSource(String accountId) {
    if (!state.activeIptvSources.contains(accountId)) return;
    final updated = [...state.activeIptvSources]..remove(accountId);
    setActiveIptvSources(updated);
  }
}
