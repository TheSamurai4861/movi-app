import 'dart:async';

import 'package:movi/src/core/storage/storage.dart';

class CloudSyncPreferences {
  CloudSyncPreferences._({
    required SecureStorageRepository storage,
    required bool autoSyncEnabled,
    required StreamController<bool> controller,
  }) : _storage = storage,
       _autoSyncEnabled = autoSyncEnabled,
       _controller = controller;

  final SecureStorageRepository _storage;
  final StreamController<bool> _controller;

  bool _autoSyncEnabled;

  static const String _key = 'prefs.cloud_sync.auto_sync_enabled';

  static Future<CloudSyncPreferences> create({
    required SecureStorageRepository storage,
  }) async {
    final raw = await storage.get(_key);
    final enabled = (raw?['value'] as bool?) ?? true;
    return CloudSyncPreferences._(
      storage: storage,
      autoSyncEnabled: enabled,
      controller: StreamController<bool>.broadcast(),
    );
  }

  /// Backward-compatible name kept for existing call sites.
  ///
  /// This value is the **user preference only**. It must not be confused with
  /// the effective cloud sync state, which also depends on authentication and
  /// premium entitlement.
  bool get autoSyncEnabled => _autoSyncEnabled;

  /// Explicit business-oriented alias for the persisted user preference.
  bool get userWantsAutoSync => _autoSyncEnabled;

  /// Backward-compatible stream kept for existing call sites.
  Stream<bool> get autoSyncEnabledStream => _controller.stream;

  /// Explicit business-oriented alias for the persisted user preference stream.
  Stream<bool> get userWantsAutoSyncStream => _controller.stream;

  Stream<bool> get autoSyncEnabledStreamWithInitial async* {
    yield _autoSyncEnabled;
    yield* _controller.stream;
  }

  Stream<bool> get userWantsAutoSyncStreamWithInitial async* {
    yield userWantsAutoSync;
    yield* _controller.stream;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    if (enabled == _autoSyncEnabled) return;
    _autoSyncEnabled = enabled;
    await _storage.put(key: _key, payload: {'value': enabled});
    if (!_controller.isClosed) {
      _controller.add(enabled);
    }
  }

  Future<void> setUserWantsAutoSync(bool enabled) {
    return setAutoSyncEnabled(enabled);
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
