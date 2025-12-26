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
  }) : _storage = storage,
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

  /// Stream emitting the current value first, then subsequent changes.
  Stream<Color> get accentColorStreamWithInitial async* {
    yield _accentColor;
    yield* _accentColorController.stream;
  }

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
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    try {
      // Accept: "AARRGGBB", "RRGGBB", and optional "0x"/"#" prefixes.
      var hex = trimmed;
      if (hex.startsWith('0x') || hex.startsWith('0X')) {
        hex = hex.substring(2);
      }
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }

      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length != 8) return null;

      final value = int.parse(hex, radix: 16);
      return Color(value);
    } catch (_) {
      return null;
    }
  }

  static String _stringifyColor(Color color) {
    // ignore: deprecated_member_use
    final argb32 = color.value;
    return argb32.toRadixString(16).padLeft(8, '0').toUpperCase();
  }
}
