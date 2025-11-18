import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:movi/src/core/theme/app_colors.dart';

/// Persisted accent color preferences with change notifications.
class AccentColorPreferences {
  AccentColorPreferences._({
    required FlutterSecureStorage storage,
    required String storageKey,
    required Color accentColor,
    required StreamController<Color> accentColorController,
  })  : _storage = storage,
        _storageKey = storageKey,
        _accentColor = accentColor,
        _accentColorController = accentColorController;

  static const String _defaultStorageKey = 'prefs.accent_color';

  /// Builds a preferences instance by reading the persisted value from storage.
  static Future<AccentColorPreferences> create({
    FlutterSecureStorage? storage,
    Color? defaultAccentColor,
    String storageKey = _defaultStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    final defaultColor = defaultAccentColor ?? AppColors.accent;
    
    final persistedColorRaw = await resolvedStorage.read(key: storageKey);
    final initialColor = _parseColor(persistedColorRaw) ?? defaultColor;

    return AccentColorPreferences._(
      storage: resolvedStorage,
      storageKey: storageKey,
      accentColor: initialColor,
      accentColorController: StreamController<Color>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKey;
  final StreamController<Color> _accentColorController;
  Color _accentColor;

  /// Currently selected accent color.
  Color get accentColor => _accentColor;

  /// Stream emitting whenever the accent color changes.
  Stream<Color> get accentColorStream => _accentColorController.stream;

  /// Persists and notifies a new accent color.
  Future<void> setAccentColor(Color color) async {
    if (color == _accentColor) return;
    _accentColor = color;
    await _storage.write(key: _storageKey, value: _stringifyColor(color));
    if (!_accentColorController.isClosed) {
      _accentColorController.add(color);
    }
  }

  /// Cleans up internal resources.
  Future<void> dispose() async {
    await _accentColorController.close();
  }

  static Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      // Format: "0xAARRGGBB" ou "0xRRGGBB"
      final value = int.parse(raw, radix: 16);
      return Color(value);
    } catch (e) {
      return null;
    }
  }

  static String _stringifyColor(Color color) {
    return color.value.toRadixString(16).toUpperCase();
  }
}

