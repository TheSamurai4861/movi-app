import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local persistence for the currently selected profile (Netflix-like).
///
/// This is intentionally stored locally first; later it can be synced to
/// Supabase in a `profiles` table, where [selectedProfileId] will correspond
/// to the primary key of the profile row linked to `auth.users.id`.
class SelectedProfilePreferences {
  SelectedProfilePreferences._({
    required FlutterSecureStorage storage,
    required String storageKey,
    required String? selectedProfileId,
    required StreamController<String?> controller,
  }) : _storage = storage,
       _storageKey = storageKey,
       _selectedProfileId = selectedProfileId,
       _controller = controller;

  static const String defaultStorageKey = 'prefs.selected_profile_id';

  static Future<SelectedProfilePreferences> create({
    FlutterSecureStorage? storage,
    String storageKey = defaultStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final raw = await resolvedStorage.read(key: storageKey);
    final initial = _normalize(raw);

    return SelectedProfilePreferences._(
      storage: resolvedStorage,
      storageKey: storageKey,
      selectedProfileId: initial,
      controller: StreamController<String?>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;
  final StreamController<String?> _controller;

  String? _selectedProfileId;

  String? get selectedProfileId => _selectedProfileId;

  Stream<String?> get selectedProfileIdStream => _controller.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<String?> get selectedProfileIdStreamWithInitial async* {
    yield _selectedProfileId;
    yield* _controller.stream;
  }

  Future<void> setSelectedProfileId(String? profileId) async {
    final normalized = _normalize(profileId);
    if (normalized == _selectedProfileId) return;

    _selectedProfileId = normalized;
    if (normalized == null) {
      await _storage.delete(key: _storageKey);
    } else {
      await _storage.write(key: _storageKey, value: normalized);
    }

    if (!_controller.isClosed) {
      _controller.add(_selectedProfileId);
    }
  }

  Future<void> clear() => setSelectedProfileId(null);

  Future<void> dispose() async {
    await _controller.close();
  }

  static String? _normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
