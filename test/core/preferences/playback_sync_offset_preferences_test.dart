import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';

void main() {
  group('PlaybackSyncOffsetPreferences', () {
    test('returns defaults when value does not exist', () async {
      final storage = _MemorySecureStorage();
      final prefs = await PlaybackSyncOffsetPreferences.create(
        storage: storage,
      );

      final value = await prefs.getForProfile('profile-a');
      expect(value, PlaybackSyncOffsets.defaults);
    });

    test('stores values per profile', () async {
      final storage = _MemorySecureStorage();
      final prefs = await PlaybackSyncOffsetPreferences.create(
        storage: storage,
      );

      await prefs.setForProfile(
        'profile-a',
        const PlaybackSyncOffsets(subtitleOffsetMs: 250, audioOffsetMs: -500),
      );
      await prefs.setForProfile(
        'profile-b',
        const PlaybackSyncOffsets(subtitleOffsetMs: -1000, audioOffsetMs: 500),
      );

      final a = await prefs.getForProfile('profile-a');
      final b = await prefs.getForProfile('profile-b');

      expect(a.subtitleOffsetMs, 250);
      expect(a.audioOffsetMs, -500);
      expect(b.subtitleOffsetMs, -1000);
      expect(b.audioOffsetMs, 500);
    });

    test('watchForProfile emits only scoped updates', () async {
      final storage = _MemorySecureStorage();
      final prefs = await PlaybackSyncOffsetPreferences.create(
        storage: storage,
      );
      final events = <PlaybackSyncOffsets>[];
      final done = Completer<void>();

      final sub = prefs.watchForProfile('profile-a').listen((value) {
        events.add(value);
        if (events.length == 2 && !done.isCompleted) {
          done.complete();
        }
      });

      await prefs.setForProfile(
        'profile-b',
        const PlaybackSyncOffsets(subtitleOffsetMs: -250, audioOffsetMs: -250),
      );
      await prefs.setForProfile(
        'profile-a',
        const PlaybackSyncOffsets(subtitleOffsetMs: 500, audioOffsetMs: 0),
      );

      await done.future.timeout(const Duration(seconds: 2));
      expect(events.first, PlaybackSyncOffsets.defaults);
      expect(events.last.subtitleOffsetMs, 500);
      expect(events.last.audioOffsetMs, 0);
      await sub.cancel();
    });

    test('fromJson clamps invalid values and falls back safely', () {
      final decoded = PlaybackSyncOffsets.fromJson(<String, Object?>{
        'subtitleOffsetMs': 999999,
        'audioOffsetMs': '-999999',
      });

      expect(decoded.subtitleOffsetMs, PlaybackSyncOffsets.maxOffsetMs);
      expect(decoded.audioOffsetMs, PlaybackSyncOffsets.minOffsetMs);
    });

    test('repairs invalid persisted payload to defaults', () async {
      final storage = _MemorySecureStorage();
      final prefs = await PlaybackSyncOffsetPreferences.create(
        storage: storage,
      );
      await storage.write(
        key:
            '${PlaybackSyncOffsetPreferences.defaultStorageKeyPrefix}profile-a',
        value: '{"broken": true, "subtitleOffsetMs": "NaN"}',
      );

      final value = await prefs.getForProfile('profile-a');
      expect(value, PlaybackSyncOffsets.defaults);
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

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
  }) async {
    _values.remove(key);
  }
}
