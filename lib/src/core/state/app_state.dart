// lib/src/core/state/app_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Représente l'état global runtime de l'application Movi.
///
/// Cet objet est **immatériel** : il ne contient aucune logique de persistance.
/// Toutes les modifications doivent passer par [copyWith] via un contrôleur
/// (ex: AppStateController) qui se charge de synchroniser avec les préférences.
class AppState extends Equatable {
  AppState({
    this.themeMode = ThemeMode.system,
    this.isOnline = true,
    this.preferredLocale = const Locale('en', 'US'),
    this.accentColor,
    this.preferredAudioLanguageCode,
    this.preferredSubtitleLanguageCode,
    Duration? iptvSyncInterval,
    Set<String>? activeIptvSources,
  })  : iptvSyncInterval =
            iptvSyncInterval ?? const Duration(minutes: 15),
        activeIptvSources =
            activeIptvSources == null || activeIptvSources.isEmpty
                ? const <String>{}
                // On protège l'état en exposant toujours un Set non modifiable.
                : Set<String>.unmodifiable(activeIptvSources);

  /// Mode de thème courant de l'application.
  final ThemeMode themeMode;

  /// Indique si l'application considère qu'elle est en ligne.
  final bool isOnline;

  /// Locale préférée de l'utilisateur.
  final Locale preferredLocale;

  /// Couleur d'accent globale de l'application.
  ///
  /// Peut être `null` si l'UI utilise la couleur par défaut du thème.
  final Color? accentColor;

  /// Code langue préférée pour l'audio du player (ex: 'en', 'fr').
  final String? preferredAudioLanguageCode;

  /// Code langue préférée pour les sous-titres du player (ex: 'en', 'fr').
  final String? preferredSubtitleLanguageCode;

  /// Intervalle de synchronisation IPTV.
  final Duration iptvSyncInterval;

  /// Identifiants des sources IPTV actuellement actives.
  final Set<String> activeIptvSources;

  /// Indique s'il existe au moins une source IPTV active.
  bool get hasActiveIptvSources => activeIptvSources.isNotEmpty;

  /// Crée une nouvelle instance de [AppState] avec certains champs modifiés.
  AppState copyWith({
    ThemeMode? themeMode,
    bool? isOnline,
    Locale? preferredLocale,
    Color? accentColor,
    String? preferredAudioLanguageCode,
    String? preferredSubtitleLanguageCode,
    Duration? iptvSyncInterval,
    Set<String>? activeIptvSources,
  }) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
      isOnline: isOnline ?? this.isOnline,
      preferredLocale: preferredLocale ?? this.preferredLocale,
      accentColor: accentColor ?? this.accentColor,
      preferredAudioLanguageCode:
          preferredAudioLanguageCode ?? this.preferredAudioLanguageCode,
      preferredSubtitleLanguageCode:
          preferredSubtitleLanguageCode ?? this.preferredSubtitleLanguageCode,
      iptvSyncInterval: iptvSyncInterval ?? this.iptvSyncInterval,
      // AppState garantit encore un Set non modifiable.
      activeIptvSources: activeIptvSources ?? this.activeIptvSources,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        isOnline,
        preferredLocale.languageCode,
        preferredLocale.countryCode,
        // ignore: deprecated_member_use
        accentColor?.value,
        preferredAudioLanguageCode,
        preferredSubtitleLanguageCode,
        iptvSyncInterval.inSeconds,
        List<String>.unmodifiable(
          activeIptvSources.toList()..sort(),
        ),
      ];
}
