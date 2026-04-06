// lib/src/core/state/app_state_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/subtitle_appearance_preferences.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';

/// Provider principal qui expose l'état global [AppState].
///
/// Version Riverpod 3 "propre" : [AppStateController] est un `Notifier<AppState>`
/// instancié par Riverpod via [NotifierProvider].
final appStateProvider = NotifierProvider<AppStateController, AppState>(
  AppStateController.new,
);

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
  return asyncValue.maybeWhen(data: (value) => value, orElse: () => fallback);
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
  return ref.watch(appStateProvider.select((state) => state.preferredLocale));
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
  return ref.watch(appStateProvider.select((state) => state.themeMode));
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

final preferredPlaybackQualityStreamProvider =
    StreamProvider<PreferredPlaybackQuality?>((ref) {
      final prefs = ref.watch(playerPreferencesProvider);
      return prefs.preferredPlaybackQualityStream;
    });

final currentPreferredPlaybackQualityProvider =
    Provider<PreferredPlaybackQuality?>((ref) {
      final prefs = ref.watch(playerPreferencesProvider);
      final asyncQuality = ref.watch(preferredPlaybackQualityStreamProvider);
      return _valueOr<PreferredPlaybackQuality?>(
        asyncQuality,
        prefs.preferredPlaybackQuality,
      );
    });

final subtitleAppearancePreferencesProvider =
    Provider<SubtitleAppearancePreferences>((ref) {
      final locator = ref.watch(slProvider);
      return locator<SubtitleAppearancePreferences>();
    });

final currentProfileSubtitleAppearanceStreamProvider =
    StreamProvider<SubtitleAppearancePrefs>((ref) {
      final prefs = ref.watch(subtitleAppearancePreferencesProvider);
      final profileId = ref.watch(selectedProfileIdProvider);
      return prefs.watchForProfile(profileId);
    });

final currentProfileSubtitleAppearanceProvider =
    Provider<SubtitleAppearancePrefs>((ref) {
      final asyncValue = ref.watch(
        currentProfileSubtitleAppearanceStreamProvider,
      );
      return _valueOr<SubtitleAppearancePrefs>(
        asyncValue,
        SubtitleAppearancePrefs.defaults,
      );
    });

class SubtitleAppearanceController {
  SubtitleAppearanceController(this._ref);

  final Ref _ref;

  Future<void> setSizePreset(SubtitleSizePreset preset) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(sizePreset: preset));
  }

  Future<void> setTextColorHex(String hex) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(textColorHex: hex));
  }

  Future<void> setFontFamilyKey(String fontFamilyKey) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(fontFamilyKey: fontFamilyKey));
  }

  Future<void> setBackgroundColorHex(String hex) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(backgroundColorHex: hex));
  }

  Future<void> setBackgroundOpacity(double opacity) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(backgroundOpacity: opacity));
  }

  Future<void> setShadowPreset(SubtitleShadowPreset shadowPreset) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(shadowPreset: shadowPreset));
  }

  Future<void> setFontScale(double fontScale) async {
    final current = await _readPersistedCurrent();
    await _persist(current.copyWith(fontScale: fontScale));
  }

  Future<void> resetToDefaults() async {
    await _persist(SubtitleAppearancePrefs.defaults);
  }

  Future<SubtitleAppearancePrefs> _readPersistedCurrent() async {
    final storage = _ref.read(subtitleAppearancePreferencesProvider);
    final profileId = _ref.read(selectedProfileIdProvider);
    return storage.getForProfile(profileId);
  }

  Future<void> _persist(SubtitleAppearancePrefs prefs) async {
    final storage = _ref.read(subtitleAppearancePreferencesProvider);
    final profileId = _ref.read(selectedProfileIdProvider);
    await storage.setForProfile(profileId, prefs);
  }
}

final subtitleAppearanceControllerProvider =
    Provider<SubtitleAppearanceController>((ref) {
      return SubtitleAppearanceController(ref);
    });

final playbackSyncOffsetPreferencesProvider =
    Provider<PlaybackSyncOffsetPreferences>((ref) {
      final locator = ref.watch(slProvider);
      return locator<PlaybackSyncOffsetPreferences>();
    });

final currentProfilePlaybackSyncOffsetsStreamProvider =
    StreamProvider<PlaybackSyncOffsets>((ref) {
      final prefs = ref.watch(playbackSyncOffsetPreferencesProvider);
      final profileId = ref.watch(selectedProfileIdProvider);
      return prefs.watchForProfile(profileId);
    });

final currentProfilePlaybackSyncOffsetsProvider = Provider<PlaybackSyncOffsets>(
  (ref) {
    final asyncValue = ref.watch(
      currentProfilePlaybackSyncOffsetsStreamProvider,
    );
    return _valueOr<PlaybackSyncOffsets>(
      asyncValue,
      PlaybackSyncOffsets.defaults,
    );
  },
);

class PlaybackSyncOffsetController {
  PlaybackSyncOffsetController(this._ref);

  final Ref _ref;

  static const List<int> quickPresetValuesMs = <int>[-500, -250, 0, 250, 500];

  Future<void> setSubtitleOffsetMs(
    int offsetMs, {
    String source = 'unknown',
  }) async {
    final current = await _readPersistedCurrent();
    final next = current.copyWith(subtitleOffsetMs: offsetMs);
    _log('set_subtitle', source: source, offsets: next);
    await _persist(next);
  }

  Future<void> setAudioOffsetMs(
    int offsetMs, {
    String source = 'unknown',
  }) async {
    final current = await _readPersistedCurrent();
    final next = current.copyWith(audioOffsetMs: offsetMs);
    _log('set_audio', source: source, offsets: next);
    await _persist(next);
  }

  Future<void> applyPresetMs(int offsetMs, {String source = 'unknown'}) async {
    final current = await _readPersistedCurrent();
    final next = current.copyWith(
      subtitleOffsetMs: offsetMs,
      audioOffsetMs: offsetMs,
    );
    _log('apply_preset', source: source, offsets: next);
    await _persist(next);
  }

  Future<void> resetOffsets({String source = 'unknown'}) async {
    _log('reset', source: source, offsets: PlaybackSyncOffsets.defaults);
    await _persist(PlaybackSyncOffsets.defaults);
  }

  Future<void> _persist(PlaybackSyncOffsets offsets) async {
    final storage = _ref.read(playbackSyncOffsetPreferencesProvider);
    final profileId = _ref.read(selectedProfileIdProvider);
    await storage.setForProfile(profileId, offsets);
  }

  Future<PlaybackSyncOffsets> _readPersistedCurrent() async {
    final storage = _ref.read(playbackSyncOffsetPreferencesProvider);
    final profileId = _ref.read(selectedProfileIdProvider);
    return storage.getForProfile(profileId);
  }

  void _log(
    String action, {
    required String source,
    required PlaybackSyncOffsets offsets,
  }) {
    final locator = _ref.read(slProvider);
    if (!locator.isRegistered<AppLogger>()) return;
    locator<AppLogger>().debug(
      '[PlayerSyncPrefs] action=$action source=$source profile=${_ref.read(selectedProfileIdProvider) ?? "__default__"} subtitleMs=${offsets.subtitleOffsetMs} audioMs=${offsets.audioOffsetMs}',
    );
  }
}

final playbackSyncOffsetControllerProvider =
    Provider<PlaybackSyncOffsetController>((ref) {
      return PlaybackSyncOffsetController(ref);
    });

final selectedIptvSourcePreferencesProvider =
    Provider<SelectedIptvSourcePreferences?>((ref) {
      final locator = ref.watch(slProvider);
      if (!locator.isRegistered<SelectedIptvSourcePreferences>()) {
        return null;
      }
      return locator<SelectedIptvSourcePreferences>();
    });

final selectedIptvSourceIdStreamProvider = StreamProvider<String?>((ref) {
  final prefs = ref.watch(selectedIptvSourcePreferencesProvider);
  return prefs?.selectedSourceIdStream ?? Stream<String?>.value(null);
});

final currentSelectedIptvSourceIdProvider = Provider<String?>((ref) {
  final prefs = ref.watch(selectedIptvSourcePreferencesProvider);
  if (prefs == null) return null;

  final asyncSourceId = ref.watch(selectedIptvSourceIdStreamProvider);
  return _valueOr<String?>(asyncSourceId, prefs.selectedSourceId);
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
  return prefs.accentColorStreamWithInitial;
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
