// lib/src/features/welcome/presentation/providers/bootstrap_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
 

import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/logging/logging.dart';

enum BootPhase { refreshing, enriching, ready }

class BootstrapState {
  const BootstrapState({
    this.phase = BootPhase.refreshing,
    this.message = 'Rafraîchissement des listes IPTV…',
  });

  final BootPhase phase;
  final String message;

  BootstrapState copyWith({BootPhase? phase, String? message}) {
    return BootstrapState(
      phase: phase ?? this.phase,
      message: message ?? this.message,
    );
  }
}

/// Contrôleur d’orchestration pour la page de bootstrap.
class BootstrapController extends Notifier<BootstrapState> {
  @override
  BootstrapState build() {
    _registerDispose();
    return const BootstrapState();
  }

  Ref get _ref => ref;
  Timer? _timeout;
  bool _started = false;

  /// Démarre la préparation: observe les événements app-layer, puis enrichit.
  void start() {
    if (_started) return;
    _started = true;
    // Log demarrage
    unawaited(LoggingService.log('Bootstrap: start'));
    // Écoute l’événement indiquant la fin de synchro IPTV.
    final bus = _ref.read(appEventBusProvider);
    bus.stream.listen((event) {
      if (event.type == AppEventType.iptvSynced && state.phase == BootPhase.refreshing) {
        unawaited(LoggingService.log('Bootstrap: IPTV synced event received'));
        _kickoffEnrich();
      }
    });

    // Timeout doux: si rien n’arrive, on passe quand même à l’enrichissement.
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 3), () {
      if (state.phase == BootPhase.refreshing) {
        unawaited(LoggingService.log('Bootstrap: timeout reached, proceeding to enrich'));
        _kickoffEnrich();
      }
    });
  }

  void _kickoffEnrich() {
    state = state.copyWith(
      phase: BootPhase.enriching,
      message: 'Préparation des métadonnées…',
    );
    // Désactivation de l’enrichissement des listes au bootstrap.
    // Spéc: LITE mode pour sections sous le héros (poster + titre uniquement).
    unawaited(
      LoggingService.log('Bootstrap: list enrichment disabled (LITE mode)'),
    );

    // Petite attente pour laisser flush les premiers patches.
    Timer(const Duration(milliseconds: 300), () {
      unawaited(LoggingService.log('Bootstrap: ready'));
      state = state.copyWith(phase: BootPhase.ready);
    });
  }

  void _registerDispose() {
    ref.onDispose(() {
      _timeout?.cancel();
      _timeout = null;
    });
  }
}

final bootstrapControllerProvider =
    NotifierProvider<BootstrapController, BootstrapState>(
  BootstrapController.new,
);
