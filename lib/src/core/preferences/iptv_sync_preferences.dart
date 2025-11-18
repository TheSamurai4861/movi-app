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

  /// Builds a preferences instance by reading the persisted value from storage.
  static Future<IptvSyncPreferences> create({
    FlutterSecureStorage? storage,
    int defaultIntervalMinutes = _defaultIntervalMinutes,
    String storageKey = _defaultStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final persistedRaw = await resolvedStorage.read(key: storageKey);
    final persistedMinutes = _parseMinutes(persistedRaw);
    final initialMinutes = persistedMinutes ?? defaultIntervalMinutes;
    final initialInterval = Duration(minutes: initialMinutes);

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
    final minutes = interval.inMinutes;
    // Si l'intervalle est très grand (comme Duration(days: 365)), considérer comme désactivé
    if (minutes < 0) {
      throw ArgumentError('Interval must be non-negative');
    }

    if (interval == _syncInterval) return;

    _syncInterval = interval;
    await _storage.write(key: _storageKey, value: minutes.toString());
    if (!_syncIntervalController.isClosed) {
      _syncIntervalController.add(interval);
    }
  }

  /// Cleans up internal resources.
  Future<void> dispose() async {
    await _syncIntervalController.close();
  }

  static int? _parseMinutes(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }
}
