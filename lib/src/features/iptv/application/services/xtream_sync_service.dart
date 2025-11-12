import 'dart:async';

import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_cache_data_source.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';

class XtreamSyncService {
  XtreamSyncService(
    this._state,
    this._refresh,
    this._cache,
    this._logger, {
    Duration? interval,
  }) : _interval = interval ?? const Duration(hours: 2);

  final AppStateController _state;
  final RefreshXtreamCatalog _refresh;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;

  Duration _interval;
  Timer? _timer;
  bool _syncing = false;
  int _tickCount = 0;
  int _refreshCount = 0;
  Duration _lastDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;

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
      for (final accountId in sources) {
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
          _logger.error('Xtream sync failed for $accountId', error, stack);
        }
      }
      sw.stop();
      _lastDuration = sw.elapsed;
      _totalDuration += _lastDuration;
      _logger.debug(
        'XtreamSync tick=$_tickCount refreshed=$_refreshCount duration=${_lastDuration.inMilliseconds}ms total=${_totalDuration.inSeconds}s',
      );
    } finally {
      _syncing = false;
    }
  }
}
