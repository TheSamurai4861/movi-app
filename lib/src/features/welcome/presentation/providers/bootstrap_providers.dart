// lib/src/features/welcome/presentation/providers/bootstrap_providers.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
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
class BootstrapController extends StateNotifier<BootstrapState> {
  BootstrapController(this._ref) : super(const BootstrapState());

  final Ref _ref;
  Timer? _timeout;
  bool _started = false;

  /// Démarre la préparation: observe HomeController, puis enrichit les premiers items visibles.
  void start() {
    if (_started) return;
    _started = true;

    // Crée le HomeController (s’il n’existe pas) et lance le load.
    // Instancie le contrôleur Home (unused local variable supprimé)
    _ref.read(hp.homeControllerProvider.notifier);
    // Log demarrage
    unawaited(LoggingService.log('Bootstrap: start'));
    // Écoute l’état pour détecter que les listes IPTV sont disponibles.
    _ref.listen<hp.HomeState>(hp.homeControllerProvider, (prev, next) {
      if (next.iptvLists.isNotEmpty && state.phase == BootPhase.refreshing) {
        unawaited(
          LoggingService.log(
            'Bootstrap: IPTV lists available (sections=${next.iptvLists.length})',
          ),
        );
        _kickoffEnrich(next);
      }
    });

    // Timeout doux: si rien n’arrive, on passe quand même à l’enrichissement.
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 3), () {
      final s = _ref.read(hp.homeControllerProvider);
      if (state.phase == BootPhase.refreshing) {
        unawaited(
          LoggingService.log(
            'Bootstrap: timeout reached, proceeding to enrich',
          ),
        );
        _kickoffEnrich(s);
      }
    });
  }

  void _kickoffEnrich(hp.HomeState homeState) {
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

  @override
  void dispose() {
    _timeout?.cancel();
    _timeout = null;
    super.dispose();
  }
}

final bootstrapControllerProvider =
    StateNotifierProvider<BootstrapController, BootstrapState>(
      (ref) => BootstrapController(ref),
    );
