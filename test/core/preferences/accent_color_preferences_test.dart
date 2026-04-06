import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/preferences/accent_color_preferences.dart';

void main() {
  group('AccentColorPreferences', () {
    test('create reads a persisted accent color from storage', () async {
      final storage = _MemorySecureStorage();
      await storage.write(
        key: 'prefs.accent_color',
        value: 'FF9C27B0',
      );

      final prefs = await AccentColorPreferences.create(storage: storage);

      expect(prefs.accentColor, const Color(0xFF9C27B0));
    });

    test('readPersistedAccentColor returns the provided default when missing', () async {
      final storage = _MemorySecureStorage();

      final color = await AccentColorPreferences.readPersistedAccentColor(
        storage: storage,
        defaultAccentColor: const Color(0xFF00BCD4),
      );

      expect(color, const Color(0xFF00BCD4));
    });
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage();

  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
      return;
    }
    _values[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
  }) async {
    return _values[key];
  }
}
