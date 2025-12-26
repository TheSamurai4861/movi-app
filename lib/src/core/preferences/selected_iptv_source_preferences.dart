import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local persistence for the currently selected IPTV source (device-local).
///
/// Stores a single source identifier (Xtream local account id) so the app can:
/// - auto-open Home when there is exactly one source
/// - ask the user to choose when there are multiple sources
/// - remember the last chosen source across app restarts
class SelectedIptvSourcePreferences {
  SelectedIptvSourcePreferences._({
    required FlutterSecureStorage storage,
    required String storageKey,
    required String? selectedSourceId,
    required StreamController<String?> controller,
  }) : _storage = storage,
       _storageKey = storageKey,
       _selectedSourceId = selectedSourceId,
       _controller = controller;

  static const String defaultStorageKey = 'prefs.selected_iptv_source_id';

  static Future<SelectedIptvSourcePreferences> create({
    FlutterSecureStorage? storage,
    String storageKey = defaultStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final raw = await resolvedStorage.read(key: storageKey);
    final initial = _normalize(raw);

    return SelectedIptvSourcePreferences._(
      storage: resolvedStorage,
      storageKey: storageKey,
      selectedSourceId: initial,
      controller: StreamController<String?>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;
  final StreamController<String?> _controller;

  String? _selectedSourceId;

  String? get selectedSourceId => _selectedSourceId;

  Stream<String?> get selectedSourceIdStream => _controller.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<String?> get selectedSourceIdStreamWithInitial async* {
    yield _selectedSourceId;
    yield* _controller.stream;
  }

  Future<void> setSelectedSourceId(String? sourceId) async {
    final normalized = _normalize(sourceId);
    if (normalized == _selectedSourceId) return;

    _selectedSourceId = normalized;
    if (normalized == null) {
      await _storage.delete(key: _storageKey);
    } else {
      await _storage.write(key: _storageKey, value: normalized);
    }

    if (!_controller.isClosed) {
      _controller.add(_selectedSourceId);
    }
  }

  Future<void> clear() => setSelectedSourceId(null);

  Future<void> dispose() async {
    await _controller.close();
  }

  static String? _normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

