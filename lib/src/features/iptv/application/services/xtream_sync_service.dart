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
    Duration? initialTickDelay,
  }) : _initialInterval = interval ?? const Duration(hours: 2),
       _interval = interval ?? const Duration(hours: 2),
       _initialTickDelay = initialTickDelay ?? Duration.zero;

  final AppStateController _state;
  final RefreshXtreamCatalog _refresh;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;

  /// Intervalle configuré initialement (préférences utilisateur / défaut).
  final Duration _initialInterval;
  final Duration _initialTickDelay;

  static const Duration _defaultInitialRefreshCooldown = Duration(seconds: 45);

  Duration _interval;
  Timer? _timer;
  Timer? _initialTimer;
  bool _syncing = false;
  int _tickCount = 0;
  int _refreshCount = 0;
  int _initialSyncCount = 0;
  int _periodicSyncCount = 0;
  Duration _lastDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _initialRefreshCooldown = _defaultInitialRefreshCooldown;
  DateTime? _lastInitialRefreshAt;
  String _startReason = 'service';

  // Compteur de ticks consécutifs où toutes les sources ont échoué.
  int _failureStreak = 0;

  static const int _maxFailureStreak = 5;
  static final Duration _maxBackoffInterval = const Duration(hours: 8);
  static const int _syncSummaryInterval = 5;

  Duration get interval => _interval;

  void setInterval(Duration interval) {
    _interval = interval;
    if (_timer != null) {
      stop();
      start();
    }
  }

  void start({
    bool skipInitialIfFresh = true,
    DateTime? initialRefreshAt,
    Duration? initialCooldown,
    String reason = 'service',
  }) {
    if (_timer != null) {
      if (initialRefreshAt != null) {
        _lastInitialRefreshAt = initialRefreshAt;
      }
      _startReason = reason;
      return;
    }
    _startReason = reason;
    if (initialCooldown != null) {
      _initialRefreshCooldown = initialCooldown;
    }
    if (initialRefreshAt != null) {
      _lastInitialRefreshAt = initialRefreshAt;
    }
    _logger.info(
      'XtreamSyncService starting (interval: ${_interval.inMinutes}m)',
    );
    _timer = Timer.periodic(_interval, (_) => _tick(reason: 'periodic'));
    _initialTimer?.cancel();
    _initialTimer = null;
    if (_initialTickDelay > Duration.zero) {
      _initialTimer = Timer(
        _initialTickDelay,
        () => unawaited(_runInitialTick(skipInitialIfFresh: skipInitialIfFresh)),
      );
      return;
    }
    unawaited(_runInitialTick(skipInitialIfFresh: skipInitialIfFresh));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _initialTimer?.cancel();
    _initialTimer = null;
    _logger.info('XtreamSyncService stopped');
  }

  Future<void> _runInitialTick({required bool skipInitialIfFresh}) async {
    if (_isWithinInitialRefreshCooldown()) {
      _logger.info(_formatInitialLog(
        action: 'skip',
        detail: 'recent_refresh',
      ));
      return;
    }
    if (skipInitialIfFresh) {
      final hasFreshSnapshot = await _hasFreshSnapshotForActiveSources();
      if (hasFreshSnapshot) {
        _logger.info(_formatInitialLog(
          action: 'skip',
          detail: 'fresh_snapshot',
        ));
        return;
      }
    }
    _logger.info(_formatInitialLog(action: 'run'));
    await _tick(reason: 'initial');
  }

  bool _isWithinInitialRefreshCooldown() {
    final lastRefresh = _lastInitialRefreshAt;
    if (lastRefresh == null) return false;
    return DateTime.now().difference(lastRefresh) < _initialRefreshCooldown;
  }

  Future<bool> _hasFreshSnapshotForActiveSources() async {
    final sources = _state.activeIptvSourceIds;
    if (sources.isEmpty) return true;
    for (final accountId in sources) {
      final snapshot = await _cache.getSnapshot(
        accountId,
        policy: XtreamCacheDataSource.snapshotPolicy,
      );
      if (snapshot == null) return false;
    }
    return true;
  }

  String _formatInitialLog({required String action, String? detail}) {
    final ts = DateTime.now().toIso8601String();
    final detailParts = <String>[
      if (detail != null) 'detail=$detail',
      'origin=$_startReason',
    ];
    final suffix = detailParts.isEmpty ? '' : ' ${detailParts.join(' ')}';
    return 'XtreamSyncService initial tick ts=$ts reason=initial '
        'action=$action$suffix';
  }

  Future<void> _tick({required String reason}) async {
    if (_syncing) return;
    if (_isWithinInitialRefreshCooldown()) {
      final ts = DateTime.now().toIso8601String();
      _logger.info(
        'XtreamSync tick ts=$ts reason=$reason action=skip detail=recent_refresh',
      );
      return;
    }
    _syncing = true;
    try {
      _tickCount += 1;
      if (reason == 'initial') {
        _initialSyncCount += 1;
      } else {
        _periodicSyncCount += 1;
      }
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
      final ts = DateTime.now().toIso8601String();
      _logger.debug(
        'XtreamSync tick ts=$ts reason=$reason action=run tick=$_tickCount '
        'refreshed=$_refreshCount '
        'duration=${_lastDuration.inMilliseconds}ms total=${_totalDuration.inSeconds}s '
        'failureStreak=$_failureStreak',
      );
      _logSyncSummaryIfNeeded();
    } finally {
      _syncing = false;
    }
  }

  void _logSyncSummaryIfNeeded() {
    final total = _initialSyncCount + _periodicSyncCount;
    if (total == 0 || total % _syncSummaryInterval != 0) return;
    final ts = DateTime.now().toIso8601String();
    _logger.info(
      'XtreamSync summary ts=$ts initial=$_initialSyncCount '
      'periodic=$_periodicSyncCount total=$total',
    );
  }
}
