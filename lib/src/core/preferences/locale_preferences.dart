import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted locale preferences with change notifications.
class LocalePreferences {
  LocalePreferences._({
    required FlutterSecureStorage storage,
    required String storageKey,
    required String languageCode,
    required StreamController<String> controller,
  })  : _storage = storage,
        _storageKey = storageKey,
        _languageCode = languageCode,
        _languageController = controller;

  static const String _defaultStorageKey = 'prefs.preferred_locale';

  /// Builds a preferences instance by reading the persisted value from storage.
  static Future<LocalePreferences> create({
    FlutterSecureStorage? storage,
    String defaultLanguageCode = 'en-US',
    String storageKey = _defaultStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final normalizedDefault = _normalize(defaultLanguageCode) ?? 'en-US';
    final persisted = await resolvedStorage.read(key: storageKey);
    final initialValue = _normalize(persisted) ?? normalizedDefault;

    return LocalePreferences._(
      storage: resolvedStorage,
      storageKey: storageKey,
      languageCode: initialValue,
      controller: StreamController<String>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;
  final StreamController<String> _languageController;
  String _languageCode;

  /// Currently selected locale code (e.g., `en-US`).
  String get languageCode => _languageCode;

  /// Stream emitting whenever the language changes.
  Stream<String> get languageStream => _languageController.stream;

  /// Persists and notifies a new language code.
  Future<void> setLanguageCode(String code) async {
    final normalized = _normalize(code);
    if (normalized == null || normalized == _languageCode) return;
    _languageCode = normalized;
    await _storage.write(key: _storageKey, value: normalized);
    if (!_languageController.isClosed) {
      _languageController.add(normalized);
    }
  }

  /// Cleans up internal resources.
  Future<void> dispose() async {
    await _languageController.close();
  }

  static String? _normalize(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
