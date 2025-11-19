import 'dart:async';

import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';

/// Service de synchronisation périodique du catalogue Xtream.
///
/// Ce service ne démarre pas tout seul : il doit être explicitement
/// démarré/arrêté par la couche supérieure (ex. bootstrap AppState / DI)
/// via `start()` et `stop()`. Il se contente de déclencher périodiquement
/// un refresh pour les comptes IPTV actifs exposés par `AppStateController`.
class XtreamSyncService {
  XtreamSyncService(
    this._state,
    this._refresh,
    this._cache,
    this._logger, {
    Duration? interval,
  }) : _initialInterval = interval ?? const Duration(hours: 2),
       _interval = interval ?? const Duration(hours: 2);

  final AppStateController _state;
  final RefreshXtreamCatalog _refresh;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;

  /// Intervalle configuré initialement (préférences utilisateur / défaut).
  final Duration _initialInterval;

  Duration _interval;
  Timer? _timer;
  bool _syncing = false;
  int _tickCount = 0;
  int _refreshCount = 0;
  Duration _lastDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Compteur de ticks consécutifs où toutes les sources ont échoué.
  int _failureStreak = 0;

  static const int _maxFailureStreak = 5;
  static final Duration _maxBackoffInterval = const Duration(hours: 8);

  Duration get interval => _interval;

  void setInterval(Duration interval) {
    _interval = interval;
    if (_timer != null) {
      stop();
      start();
    }
  }

  void start() {
    if (_timer != null) return;
    _logger.info(
      'XtreamSyncService starting (interval: ${_interval.inMinutes}m)',
    );
    _timer = Timer.periodic(_interval, (_) => _tick());
    // initial tick
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _logger.info('XtreamSyncService stopped');
  }

  Future<void> _tick() async {
    if (_syncing) return;
    _syncing = true;
    try {
      _tickCount += 1;
      final sw = Stopwatch()..start();
      final sources = _state.activeIptvSourceIds;
      if (sources.isEmpty) return;

      int totalAccounts = 0;
      int failedAccounts = 0;

      for (final accountId in sources) {
        totalAccounts += 1;
        try {
          final snapshot = await _cache.getSnapshot(
            accountId,
            policy: XtreamCacheDataSource.snapshotPolicy,
          );
          if (snapshot == null) {
            _logger.info('Xtream sync: refreshing account $accountId');
            await _refresh(accountId);
            _refreshCount += 1;
          }
        } catch (error, stack) {
          failedAccounts += 1;
          _logger.error('Xtream sync failed for $accountId', error, stack);
        }
      }

      // Gestion du backoff simple en cas d'échecs répétés.
      if (totalAccounts > 0 && failedAccounts == totalAccounts) {
        _failureStreak += 1;
        if (_failureStreak >= _maxFailureStreak &&
            _interval < _maxBackoffInterval) {
          final newInterval = _interval * 2;
          final clamped = newInterval > _maxBackoffInterval
              ? _maxBackoffInterval
              : newInterval;
          if (clamped != _interval) {
            _logger.warn(
              'XtreamSync backoff enabled: failureStreak=$_failureStreak, '
              'interval: ${_interval.inMinutes}m → ${clamped.inMinutes}m',
            );
            setInterval(clamped);
          }
        }
      } else if (failedAccounts == 0 && _failureStreak != 0) {
        // Toutes les sources ont réussi, on réinitialise le compteur et
        // on revient progressivement à l’intervalle initial si nécessaire.
        _failureStreak = 0;
        if (_interval > _initialInterval) {
          final newInterval = _interval ~/ 2;
          final clamped = newInterval < _initialInterval
              ? _initialInterval
              : newInterval;
          if (clamped != _interval) {
            _logger.info(
              'XtreamSync backoff reset: interval ${_interval.inMinutes}m → ${clamped.inMinutes}m',
            );
            setInterval(clamped);
          }
        }
      }

      sw.stop();
      _lastDuration = sw.elapsed;
      _totalDuration += _lastDuration;
      _logger.debug(
        'XtreamSync tick=$_tickCount refreshed=$_refreshCount '
        'duration=${_lastDuration.inMilliseconds}ms total=${_totalDuration.inSeconds}s '
        'failureStreak=$_failureStreak',
      );
    } finally {
      _syncing = false;
    }
  }
}
