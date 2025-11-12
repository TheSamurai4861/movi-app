import 'dart:async';

import '../../../di/injector.dart';
import '../../../state/app_state_controller.dart';
import '../../../utils/logger.dart';
import '../../data/datasources/xtream_cache_data_source.dart';
import '../usecases/refresh_xtream_catalog.dart';

class XtreamSyncService {
  XtreamSyncService(
    this._state,
    this._refresh,
    this._cache, {
    AppLogger? logger,
    Duration? interval,
  }) : _logger = logger ?? sl<AppLogger>(),
       _interval = interval ?? const Duration(hours: 2);

  final AppStateController _state;
  final RefreshXtreamCatalog _refresh;
  final XtreamCacheDataSource _cache;
  final AppLogger _logger;

  Duration _interval;
  Timer? _timer;
  bool _syncing = false;

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
          }
        } catch (error, stack) {
          _logger.error('Xtream sync failed for $accountId', error, stack);
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
