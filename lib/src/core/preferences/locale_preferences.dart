import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted locale preferences with change notifications.
class LocalePreferences {
  LocalePreferences._({
    required FlutterSecureStorage storage,
    required String storageKey,
    required String languageCode,
    required StreamController<String> languageController,
    required String themeStorageKey,
    required ThemeMode themeMode,
    required StreamController<ThemeMode> themeController,
  }) : _storage = storage,
       _storageKey = storageKey,
       _languageCode = languageCode,
       _languageController = languageController,
       _themeStorageKey = themeStorageKey,
       _themeMode = themeMode,
       _themeController = themeController;

  static const String _defaultStorageKey = 'prefs.preferred_locale';

  /// Builds a preferences instance by reading the persisted value from storage.
  static Future<LocalePreferences> create({
    FlutterSecureStorage? storage,
    String defaultLanguageCode = 'en-US',
    String storageKey = _defaultStorageKey,
    String themeStorageKey = 'prefs.theme_mode',
    ThemeMode defaultThemeMode = ThemeMode.system,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final normalizedDefault = _normalize(defaultLanguageCode) ?? 'en-US';
    final persistedLang = await resolvedStorage.read(key: storageKey);
    final initialLang = _normalize(persistedLang) ?? normalizedDefault;

    final persistedThemeRaw = await resolvedStorage.read(key: themeStorageKey);
    final initialTheme = _parseTheme(persistedThemeRaw) ?? defaultThemeMode;

    return LocalePreferences._(
      storage: resolvedStorage,
      storageKey: storageKey,
      languageCode: initialLang,
      languageController: StreamController<String>.broadcast(),
      themeStorageKey: themeStorageKey,
      themeMode: initialTheme,
      themeController: StreamController<ThemeMode>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;
  final StreamController<String> _languageController;
  String _languageCode;
  final String _themeStorageKey;
  final StreamController<ThemeMode> _themeController;
  ThemeMode _themeMode;

  /// Currently selected locale code (e.g., `en-US`).
  String get languageCode => _languageCode;

  /// Stream emitting whenever the language changes.
  Stream<String> get languageStream => _languageController.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<String> get languageStreamWithInitial async* {
    yield _languageCode;
    yield* _languageController.stream;
  }

  ThemeMode get themeMode => _themeMode;

  Stream<ThemeMode> get themeStream => _themeController.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield _themeMode;
    yield* _themeController.stream;
  }

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

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    await _storage.write(key: _themeStorageKey, value: _stringifyTheme(mode));
    if (!_themeController.isClosed) {
      _themeController.add(mode);
    }
  }

  /// Cleans up internal resources.
  Future<void> dispose() async {
    await _languageController.close();
    await _themeController.close();
  }

  static String? _normalize(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    return _canonicalizeLocaleTag(trimmed.replaceAll('_', '-'));
  }

  static String? _canonicalizeLocaleTag(String raw) {
    final parts = raw
        .split('-')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return null;

    final out = <String>[];
    out.add(parts.first.toLowerCase());

    for (var i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.length == 4 && _isAlpha(p)) {
        out.add(p[0].toUpperCase() + p.substring(1).toLowerCase());
        continue;
      }
      if (p.length == 2 && _isAlpha(p)) {
        out.add(p.toUpperCase());
        continue;
      }
      if (p.length == 3 && _isNumeric(p)) {
        out.add(p);
        continue;
      }
      out.add(p.toLowerCase());
    }

    return out.join('-');
  }

  static bool _isAlpha(String s) =>
      s.codeUnits.every((c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122));

  static bool _isNumeric(String s) =>
      s.codeUnits.every((c) => c >= 48 && c <= 57);

  static ThemeMode? _parseTheme(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  static String _stringifyTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
