import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted IPTV sync interval preferences with change notifications.
class IptvSyncPreferences {
  IptvSyncPreferences._({
    required FlutterSecureStorage storage,
    required String storageKey,
    required Duration syncInterval,
    required StreamController<Duration> syncIntervalController,
  }) : _storage = storage,
       _storageKey = storageKey,
       _syncInterval = syncInterval,
       _syncIntervalController = syncIntervalController;

  static const String _defaultStorageKey = 'prefs.iptv_sync_interval_minutes';
  static const int _defaultIntervalMinutes = 120; // 2 heures
  static const Duration disabledInterval = Duration(days: 365);
  static const String _disabledSentinel = 'disabled';

  /// Builds a preferences instance by reading the persisted value from storage.
  static Future<IptvSyncPreferences> create({
    FlutterSecureStorage? storage,
    int defaultIntervalMinutes = _defaultIntervalMinutes,
    String storageKey = _defaultStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final persistedRaw = await resolvedStorage.read(key: storageKey);
    final initialInterval =
        _parseInterval(persistedRaw) ??
        Duration(minutes: defaultIntervalMinutes);

    return IptvSyncPreferences._(
      storage: resolvedStorage,
      storageKey: storageKey,
      syncInterval: initialInterval,
      syncIntervalController: StreamController<Duration>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;
  final StreamController<Duration> _syncIntervalController;
  Duration _syncInterval;

  /// Currently selected sync interval.
  Duration get syncInterval => _syncInterval;

  /// Stream emitting whenever the sync interval changes.
  Stream<Duration> get syncIntervalStream => _syncIntervalController.stream;

  /// Persists and notifies a new sync interval.
  Future<void> setSyncInterval(Duration interval) async {
    if (interval.isNegative) {
      throw ArgumentError('Interval must be non-negative');
    }

    if (interval == _syncInterval) return;

    _syncInterval = interval;

    if (interval >= disabledInterval) {
      await _storage.write(key: _storageKey, value: _disabledSentinel);
    } else {
      await _storage.write(
        key: _storageKey,
        value: interval.inMinutes.toString(),
      );
    }
    if (!_syncIntervalController.isClosed) {
      _syncIntervalController.add(interval);
    }
  }

  /// Stream emitting the current value first, then subsequent changes.
  Stream<Duration> get syncIntervalStreamWithInitial async* {
    yield _syncInterval;
    yield* _syncIntervalController.stream;
  }

  bool get isSyncDisabled => _syncInterval >= disabledInterval;

  /// Cleans up internal resources.
  Future<void> dispose() async {
    await _syncIntervalController.close();
  }

  static Duration? _parseInterval(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.toLowerCase() == _disabledSentinel) {
      return disabledInterval;
    }

    final minutes = int.tryParse(trimmed);
    if (minutes == null) return null;
    if (minutes < 0) return null;

    // Back-compat: if a previous version stored a huge interval to mean disabled.
    if (Duration(minutes: minutes) >= disabledInterval) {
      return disabledInterval;
    }

    return Duration(minutes: minutes);
  }
}





