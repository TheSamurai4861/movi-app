// lib/src/core/state/app_state_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/state/app_state.dart';

/// Contrôleur central de l'état applicatif.
///
/// - Expose un sous-ensemble d'accès en lecture seule pour éviter
///   toute manipulation directe de `state` par l'extérieur.
/// - Applique des mises à jour idempotentes (early-return) afin d'éviter
///   des rebuilds inutiles.
/// - Garantit l'immuabilité des collections exposées.
class AppStateController extends StateNotifier<AppState> {
  AppStateController(this._localePreferences)
    : super(
        AppState(
          preferredLocale: _localePreferences.languageCode,
          themeMode: _localePreferences.themeMode,
        ),
      );

  final LocalePreferences _localePreferences;
  StreamSubscription<String>? _localeSubscription;
  StreamSubscription<ThemeMode>? _themeSubscription;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Identifiants des sources IPTV actives (ensemble non modifiable).
  Set<String> get activeIptvSourceIds =>
      Set.unmodifiable(state.activeIptvSources);

  /// Indique s'il existe au moins une source IPTV active.
  bool get hasActiveIptvSources => state.activeIptvSources.isNotEmpty;

  bool get hasNoActiveIptvSources => state.activeIptvSources.isEmpty;

  String get preferredLocale => state.preferredLocale;
  ThemeMode get themeMode => state.themeMode;

  /// Définit le mode thème si celui-ci diffère de l'état courant.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;
    await _localePreferences.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  /// Met à jour l'état de connectivité si celui-ci a changé.
  void setConnectivity(bool isOnline) {
    if (state.isOnline == isOnline) return;
    state = state.copyWith(isOnline: isOnline);
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

    state = state.copyWith(activeIptvSources: Set.unmodifiable(sanitized));
  }

  /// Définit la langue préférée et la persiste via [LocalePreferences].
  Future<void> setPreferredLocale(String locale) async {
    final value = locale.trim();
    if (value.isEmpty || state.preferredLocale == value) return;
    await _localePreferences.setLanguageCode(value);
    state = state.copyWith(preferredLocale: value);
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

  @override
  void dispose() {
    _localeSubscription?.cancel();
    _themeSubscription?.cancel();
    // Fire-and-forget la fermeture du StreamController
    unawaited(_connectivityController.close());
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }

  void attachLocaleStream() {
    _localeSubscription?.cancel();
    _themeSubscription?.cancel();
    _localeSubscription = _localePreferences.languageStream.listen((code) {
      if (code.isNotEmpty && code != state.preferredLocale) {
        state = state.copyWith(preferredLocale: code);
      }
    });
    _themeSubscription = _localePreferences.themeStream.listen((mode) {
      if (mode != state.themeMode) {
        state = state.copyWith(themeMode: mode);
      }
    });
  }
}
