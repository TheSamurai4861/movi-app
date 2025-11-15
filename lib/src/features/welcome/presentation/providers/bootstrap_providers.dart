// lib/src/features/welcome/presentation/providers/bootstrap_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart' as app_startup_provider;
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'dart:async';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/di/di.dart';

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
      if (event.type == AppEventType.iptvSynced &&
          state.phase == BootPhase.refreshing) {
        unawaited(LoggingService.log('Bootstrap: IPTV synced event received'));
        _kickoffEnrich();
      }
    });

    // Timeout doux: si rien n’arrive, on passe quand même à l’enrichissement.
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 3), () {
      if (state.phase == BootPhase.refreshing) {
        unawaited(
          LoggingService.log(
            'Bootstrap: timeout reached, proceeding to enrich',
          ),
        );
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

final appPreloadProvider = FutureProvider<void>((ref) async {
  await ref.read(app_startup_provider.appStartupProvider.future);
  final appState = ref.read(appStateControllerProvider);
  if (appState.hasNoActiveIptvSources) {
    final locator = ref.read(slProvider);
    final iptvRepo = locator<IptvLocalRepository>();
    final accounts = await iptvRepo.getAccounts();
    if (accounts.isNotEmpty) {
      final ids = accounts.map((a) => a.id).toSet();
      appState.setActiveIptvSources(ids);
    }
  }
  final initial = ref.read(homeControllerProvider);
  final home = ref.read(homeControllerProvider.notifier);

  final hasData = initial.error == null && (
    initial.hero.isNotEmpty ||
    initial.cwMovies.isNotEmpty ||
    initial.cwShows.isNotEmpty ||
    initial.iptvLists.isNotEmpty
  );

  if (hasData) {
    return;
  }

  try {
    await home.load().timeout(const Duration(seconds: 10));
  } on TimeoutException {
    final after = ref.read(homeControllerProvider);
    final partial = after.hero.isNotEmpty ||
        after.cwMovies.isNotEmpty ||
        after.cwShows.isNotEmpty ||
        after.iptvLists.isNotEmpty;
    if (!partial) {
      throw AppPreloadTimeoutException('Home load timeout');
    }
  } catch (e) {
    unawaited(LoggingService.log('Home preload failed: $e'));
    final after = ref.read(homeControllerProvider);
    final partial = after.hero.isNotEmpty ||
        after.cwMovies.isNotEmpty ||
        after.cwShows.isNotEmpty ||
        after.iptvLists.isNotEmpty;
    if (!partial) {
      rethrow;
    }
  }
});

class AppPreloadTimeoutException implements Exception {
  AppPreloadTimeoutException(this.message);
  final String message;
  @override
  String toString() => 'AppPreloadTimeoutException: $message';
}
