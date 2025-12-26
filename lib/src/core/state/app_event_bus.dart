import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Types d'événements globaux que l'application peut émettre.
///
/// On commence avec `iptvSynced`, mais l'énum peut être étendue plus tard
/// (ex: userLoggedOut, libraryRefreshed, etc.).
enum AppEventType {
  iptvSynced,
  librarySynced,
}

/// Événement global propagé via [AppEventBus].
///
/// Contient au minimum un [type], et peut être enrichi plus tard
/// avec des payloads (ex: identifiant de compte, message, etc.).
class AppEvent {
  const AppEvent(this.type);

  /// Type de l'événement (catégorie).
  final AppEventType type;
}

/// Bus d'événements applicatif simple, basé sur un [StreamController].
///
/// Permet de diffuser des événements ponctuels (fire-and-forget) à
/// différentes parties de l'application sans passer par l'état global
/// persistant (ex: "IPTV synchronisé", "playlist mise à jour", etc.).
class AppEventBus {
  AppEventBus();

  /// StreamController en mode broadcast pour permettre plusieurs listeners.
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  /// Flux des événements émis par l'application.
  Stream<AppEvent> get stream => _controller.stream;

  /// Émet un [event] s'il est encore possible de le faire.
  ///
  /// La vérification [_controller.isClosed] évite les exceptions si
  /// l'application tente d'émettre après la fermeture du bus.
  void emit(AppEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Ferme le bus et libère les ressources associées.
  void dispose() {
    _controller.close();
  }
}

/// Provider Riverpod pour l'[AppEventBus].
///
/// Crée une instance de bus et la ferme automatiquement quand le
/// provider est détruit (ex: fin de la durée de vie de l'application
/// ou nettoyage dans les tests).
final appEventBusProvider = Provider<AppEventBus>((ref) {
  final bus = AppEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
