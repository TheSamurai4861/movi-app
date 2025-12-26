// lib/src/core/state/app_state_controller.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/state/app_state.dart';

/// Contrôleur central de l'état applicatif.
///
/// Version Riverpod 3 (`Notifier<AppState>`), sans API legacy.
/// - Initialise l'état à partir de [LocalePreferences].
/// - Synchronise l'état avec les streams de préférences (langue / thème).
/// - Expose des méthodes "safe" (early-return) pour éviter les rebuilds inutiles.
/// - Gère aussi un petit bus de connectivité + la liste des sources IPTV actives.
/// - Fournit une API `addListener` pour les consommateurs externes
///   (ex: `LaunchRedirectGuard`) qui veulent réagir aux changements de state.
class AppStateController extends Notifier<AppState> {
  late final LocalePreferences _localePreferences;

  StreamSubscription<String>? _localeSubscription;
  StreamSubscription<ThemeMode>? _themeSubscription;
  late final StreamController<bool> _connectivityController;

  /// Liste des listeners externes (LaunchRedirectGuard, etc.).
  final List<void Function(AppState)> _externalListeners = [];

  /// Stream de l'état de connectivité logique de l'app.
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Identifiants des sources IPTV actives (ensemble non modifiable).
  Set<String> get activeIptvSourceIds =>
      Set.unmodifiable(state.activeIptvSources);

  /// Identifiants des sources IPTV à privilégier pour la lecture/recherche.
  ///
  /// Si une source est explicitement sélectionnée, on la privilégie pour éviter
  /// les collisions entre comptes multiples.
  Set<String> get preferredIptvSourceIds {
    if (!sl.isRegistered<SelectedIptvSourcePreferences>()) {
      return activeIptvSourceIds;
    }
    final selected = sl<SelectedIptvSourcePreferences>().selectedSourceId;
    if (selected == null || selected.isEmpty) {
      return activeIptvSourceIds;
    }
    if (activeIptvSourceIds.isEmpty ||
        activeIptvSourceIds.contains(selected)) {
      return {selected};
    }
    return activeIptvSourceIds;
  }

  /// Indique s'il existe au moins une source IPTV active.
  bool get hasActiveIptvSources => state.activeIptvSources.isNotEmpty;

  bool get hasNoActiveIptvSources => state.activeIptvSources.isEmpty;

  /// Locale préférée courante (type fort `Locale`).
  Locale get preferredLocale => state.preferredLocale;

  /// Mode de thème courant.
  ThemeMode get themeMode => state.themeMode;

  @override
  AppState build() {
    // Récupère les dépendances via GetIt pour rester compatible
    // avec le wiring existant.
    _localePreferences = sl<LocalePreferences>();
    _connectivityController = StreamController<bool>.broadcast();

    // État initial issu des préférences persistées.
    final initialLocaleCode = _localePreferences.languageCode;
    final initialLocale = _parseLocaleCode(initialLocaleCode);

    final initialState = AppState(
      preferredLocale: initialLocale,
      themeMode: _localePreferences.themeMode,
    );

    // Abonnements aux changements de préférences (langue / thème).
    _attachLocaleStream();

    // Clean-up automatique quand le provider est détruit.
    ref.onDispose(() {
      _localeSubscription?.cancel();
      _themeSubscription?.cancel();
      _connectivityController.close();
      _externalListeners.clear();
    });

    return initialState;
  }

  /// API compatible avec `StateNotifier.addListener`.
  ///
  /// Permet à des services externes (comme `LaunchRedirectGuard`) de réagir
  /// aux changements de [AppState] sans dépendre de Riverpod.
  ///
  /// Retourne une fonction à appeler pour se désabonner.
  void Function() addListener(void Function(AppState) listener) {
    _externalListeners.add(listener);
    // On émet l'état courant immédiatement pour aligner le comportement.
    listener(state);
    return () {
      _externalListeners.remove(listener);
    };
  }

  // ---------------------------------------------------------------------------
  // Mutateurs publics
  // ---------------------------------------------------------------------------

  /// Définit le mode thème si celui-ci diffère de l'état courant.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;

    await _localePreferences.setThemeMode(mode);
    _setState(state.copyWith(themeMode: mode));
  }

  /// Met à jour l'état de connectivité si celui-ci a changé.
  void setConnectivity(bool isOnline) {
    if (state.isOnline == isOnline) return;

    _setState(state.copyWith(isOnline: isOnline));
    if (!_connectivityController.isClosed) {
      _connectivityController.add(isOnline);
    }
  }

  /// Remplace la liste des sources IPTV actives (copie immuable, dédupliquée).
  void setActiveIptvSources(Set<String> sources) {
    final sanitized = sources
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    if (_setsEqual(state.activeIptvSources, sanitized)) return;

    _setState(
      state.copyWith(
        activeIptvSources: Set<String>.unmodifiable(sanitized),
      ),
    );
  }

  /// Définit la langue préférée et la persiste via [LocalePreferences].
  ///
  /// L'UI travaille avec un [Locale] typé, le contrôleur se charge
  /// de la conversion en code BCP-47 pour la persistance.
  Future<void> setPreferredLocale(Locale locale) async {
    if (locale == state.preferredLocale) return;

    final code = _localeToCode(locale);

    await _localePreferences.setLanguageCode(code);
    _setState(state.copyWith(preferredLocale: locale));
  }

  /// Ajoute une source IPTV si absente.
  void addIptvSource(String accountId) {
    final id = accountId.trim();
    if (id.isEmpty || state.activeIptvSources.contains(id)) return;

    final updated = state.activeIptvSources.toSet()..add(id);
    setActiveIptvSources(updated);
  }

  /// Retire une source IPTV si présente.
  void removeIptvSource(String accountId) {
    final id = accountId.trim();
    if (id.isEmpty || !state.activeIptvSources.contains(id)) return;

    final updated = state.activeIptvSources.toSet()..remove(id);
    setActiveIptvSources(updated);
  }

  // ---------------------------------------------------------------------------
  // Helpers internes
  // ---------------------------------------------------------------------------

  bool _setsEqual(Set<String> a, Set<String> b) => setEquals(a, b);

  /// Convertit un code BCP-47 (ex: 'en', 'en-US') en [Locale].
  Locale _parseLocaleCode(String? code) {
    if (code == null || code.isEmpty) {
      return const Locale('en', 'US');
    }

    final parts = code.split('-');
    if (parts.length == 1) {
      return Locale(parts[0]);
    }

    return Locale(parts[0], parts[1]);
  }

  /// Convertit un [Locale] en code BCP-47 (ex: 'en-US').
  String _localeToCode(Locale locale) {
    final country = locale.countryCode;
    if (country == null || country.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$country';
  }

  void _attachLocaleStream() {
    _localeSubscription?.cancel();
    _themeSubscription?.cancel();

    _localeSubscription = _localePreferences.languageStream.listen((code) {
      final locale = _parseLocaleCode(code);

      if (locale == state.preferredLocale) return;

      _setState(state.copyWith(preferredLocale: locale));
    });

    _themeSubscription = _localePreferences.themeStream.listen((mode) {
      if (mode == state.themeMode) return;

      _setState(state.copyWith(themeMode: mode));
    });
  }

  /// Point central pour changer `state` + notifier les listeners externes.
  void _setState(AppState newState) {
    if (identical(newState, state) || newState == state) return;

    state = newState;

    // On clone la liste pour éviter les modifs pendant l'itération.
    final listeners = List<void Function(AppState)>.from(_externalListeners);
    for (final listener in listeners) {
      listener(newState);
    }
  }
}
