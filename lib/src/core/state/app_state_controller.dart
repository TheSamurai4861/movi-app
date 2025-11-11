// lib/src/core/state/app_state_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'app_state.dart';
import '../preferences/locale_preferences.dart';

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
          ),
        );

  final LocalePreferences _localePreferences;

  /// Identifiants des sources IPTV actives (liste non modifiable).
  List<String> get activeIptvSourceIds =>
      List.unmodifiable(state.activeIptvSources);

  /// Indique s'il existe au moins une source IPTV active.
  bool get hasActiveIptvSources => state.activeIptvSources.isNotEmpty;

  /// Définit le mode thème si celui-ci diffère de l'état courant.
  void setThemeMode(ThemeMode mode) {
    if (state.themeMode == mode) return;
    state = state.copyWith(themeMode: mode);
  }

  /// Met à jour l'état de connectivité si celui-ci a changé.
  void setConnectivity(bool isOnline) {
    if (state.isOnline == isOnline) return;
    state = state.copyWith(isOnline: isOnline);
  }

  /// Remplace la liste des sources IPTV actives (copie immuable, dédupliquée).
  void setActiveIptvSources(List<String> sources) {
    final sanitized = sources.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (_listsEqual(state.activeIptvSources, sanitized)) return;
    state = state.copyWith(activeIptvSources: List.unmodifiable(sanitized));
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
    final updated = <String>[...state.activeIptvSources, id];
    setActiveIptvSources(updated);
  }

  /// Retire une source IPTV si présente.
  void removeIptvSource(String accountId) {
    final id = accountId.trim();
    if (id.isEmpty || !state.activeIptvSources.contains(id)) return;
    final updated = <String>[...state.activeIptvSources]..remove(id);
    setActiveIptvSources(updated);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _listsEqual(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
