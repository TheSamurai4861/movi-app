// lib/src/core/state/app_state_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/theme/app_colors.dart';

/// Provider principal qui expose l'état global [AppState].
///
/// Version Riverpod 3 "propre" : [AppStateController] est un `Notifier<AppState>`
/// instancié par Riverpod via [NotifierProvider].
final appStateProvider =
    NotifierProvider<AppStateController, AppState>(AppStateController.new);

/// Alias pratique pour accéder directement au contrôleur.
///
/// Exemple d'usage :
/// ```dart
/// ref.read(appStateControllerProvider).setThemeMode(ThemeMode.dark);
/// ```
final appStateControllerProvider = Provider<AppStateController>((ref) {
  return ref.read(appStateProvider.notifier);
});

/// Helper générique pour récupérer la valeur d'un [AsyncValue]
/// ou tomber sur une valeur de repli si le stream n'a pas encore émis.
T _valueOr<T>(AsyncValue<T> asyncValue, T fallback) {
  return asyncValue.maybeWhen(
    data: (value) => value,
    orElse: () => fallback,
  );
}

/// Convertit un [Locale] en code BCP-47 (ex: 'fr-FR').
String _localeToCode(Locale locale) {
  final country = locale.countryCode;
  if (country == null || country.isEmpty) {
    return locale.languageCode;
  }
  return '${locale.languageCode}-$country';
}

//
// ───────────────────────── ÉTAT GLOBAL DÉRIVÉ ──────────────────────
//

/// Provider booléen de connectivité (vue logique de l'app).
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider.select((state) => state.isOnline));
});

/// Provider des identifiants de sources IPTV actives.
final activeIptvSourcesProvider = Provider<Set<String>>((ref) {
  return ref.watch(appStateProvider.select((state) => state.activeIptvSources));
});

/// Indique s'il existe au moins une source IPTV active.
final hasActiveIptvSourcesProvider = Provider<bool>((ref) {
  return ref.watch(
    appStateProvider.select((state) => state.activeIptvSources.isNotEmpty),
  );
});

/// Indique s'il n'existe aucune source IPTV active.
final hasNoActiveIptvSourcesProvider = Provider<bool>((ref) {
  return ref.watch(
    appStateProvider.select((state) => state.activeIptvSources.isEmpty),
  );
});

//
// ───────────────────────── LOCALE / LANGUE ─────────────────────────
//

/// Locale courante de l'application.
///
/// Dérivée directement de [AppState.preferredLocale], qui lui-même
/// est synchronisé avec [LocalePreferences] via [AppStateController].
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(
    appStateProvider.select((state) => state.preferredLocale),
  );
});

/// Code de langue courant (string brute, ex: 'fr-FR').
final currentLanguageCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(
    appStateProvider.select((state) => state.preferredLocale),
  );
  return _localeToCode(locale);
});

//
// ───────────────────────── THÈME (DARK/LIGHT) ──────────────────────
//

/// [ThemeMode] courant de l'application.
///
/// Dérivé directement de [AppState.themeMode].
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(
    appStateProvider.select((state) => state.themeMode),
  );
});

//
// ───────────────────────── IPTV SYNC ───────────────────────────────
//

/// Provider des préférences de synchronisation IPTV.
///
/// Pour l'instant ces préférences ne sont pas encore réinjectées dans
/// [AppState] : on lit directement les prefs. On pourra les migrer
/// plus tard dans le contrôleur global si nécessaire.
final iptvSyncPreferencesProvider = Provider<IptvSyncPreferences>((ref) {
  final sl = ref.watch(slProvider);
  return sl<IptvSyncPreferences>();
});

/// Stream de l'intervalle de synchronisation IPTV.
final iptvSyncIntervalStreamProvider = StreamProvider<Duration>((ref) {
  final prefs = ref.watch(iptvSyncPreferencesProvider);
  return prefs.syncIntervalStream;
});

/// Intervalle courant de synchronisation IPTV.
final currentIptvSyncIntervalProvider = Provider<Duration>((ref) {
  final prefs = ref.watch(iptvSyncPreferencesProvider);

  final asyncInterval = ref.watch(iptvSyncIntervalStreamProvider);
  return _valueOr<Duration>(asyncInterval, prefs.syncInterval);
});

//
// ───────────────────────── PRÉFÉRENCES LECTEUR ─────────────────────
//

/// Provider des préférences du lecteur (audio / sous-titres, etc.).
///
/// Comme pour IPTV, ces valeurs peuvent être intégrées plus tard
/// dans [AppState] si tu veux un state global unique.
final playerPreferencesProvider = Provider<PlayerPreferences>((ref) {
  final sl = ref.watch(slProvider);
  return sl<PlayerPreferences>();
});

/// Stream de la langue audio préférée.
final preferredAudioLanguageStreamProvider = StreamProvider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);
  return prefs.preferredAudioLanguageStream;
});

/// Langue audio préférée courante.
final currentPreferredAudioLanguageProvider = Provider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);

  final asyncLang = ref.watch(preferredAudioLanguageStreamProvider);
  return _valueOr<String?>(asyncLang, prefs.preferredAudioLanguage);
});

/// Stream de la langue de sous-titres préférée.
final preferredSubtitleLanguageStreamProvider = StreamProvider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);
  return prefs.preferredSubtitleLanguageStream;
});

/// Langue de sous-titres préférée courante.
final currentPreferredSubtitleLanguageProvider = Provider<String?>((ref) {
  final prefs = ref.watch(playerPreferencesProvider);

  final asyncLang = ref.watch(preferredSubtitleLanguageStreamProvider);
  return _valueOr<String?>(asyncLang, prefs.preferredSubtitleLanguage);
});

//
// ───────────────────────── COULEUR D'ACCENT ────────────────────────
//

/// Provider des préférences de couleur d'accent.
final accentColorPreferencesProvider = Provider<AccentColorPreferences>((ref) {
  final sl = ref.watch(slProvider);
  return sl<AccentColorPreferences>();
});

/// Stream de la couleur d'accent personnalisée.
final accentColorStreamProvider = StreamProvider<Color>((ref) {
  final locator = ref.watch(slProvider);
  if (!locator.isRegistered<AccentColorPreferences>()) {
    return Stream.value(AppColors.accent);
  }
  final prefs = locator<AccentColorPreferences>();
  return prefs.accentColorStream;
});

/// Couleur d'accent courante.
final currentAccentColorProvider = Provider<Color>((ref) {
  final locator = ref.watch(slProvider);
  if (!locator.isRegistered<AccentColorPreferences>()) {
    return AppColors.accent;
  }
  final prefs = locator<AccentColorPreferences>();

  final asyncColor = ref.watch(accentColorStreamProvider);
  return _valueOr<Color>(asyncColor, prefs.accentColor);
});
