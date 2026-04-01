import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/playback_sync_offset_preferences.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/state/app_state_provider.dart';

void main() {
  group('PlaybackSyncOffsetController', () {
    test('setters persist offsets per profile', () async {
      final storage = _MemorySecureStorage();
      final prefs = await PlaybackSyncOffsetPreferences.create(
        storage: storage,
      );
      final container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(GetIt.asNewInstance()),
          selectedProfileIdProvider.overrideWithValue('profile-a'),
          playbackSyncOffsetPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(prefs.dispose);

      final controller = container.read(playbackSyncOffsetControllerProvider);
      await controller.setSubtitleOffsetMs(250, source: 'test_subtitle');
      await controller.setAudioOffsetMs(-500, source: 'test_audio');

      final stored = await prefs.getForProfile('profile-a');
      expect(stored.subtitleOffsetMs, 250);
      expect(stored.audioOffsetMs, -500);
    });

    test(
      'applyPresetMs updates both offsets and resetOffsets restores defaults',
      () async {
        final storage = _MemorySecureStorage();
        final prefs = await PlaybackSyncOffsetPreferences.create(
          storage: storage,
        );
        final container = ProviderContainer(
          overrides: [
            slProvider.overrideWithValue(GetIt.asNewInstance()),
            selectedProfileIdProvider.overrideWithValue('profile-a'),
            playbackSyncOffsetPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(prefs.dispose);

        final controller = container.read(playbackSyncOffsetControllerProvider);
        await controller.applyPresetMs(500, source: 'test_preset');
        var stored = await prefs.getForProfile('profile-a');
        expect(stored.subtitleOffsetMs, 500);
        expect(stored.audioOffsetMs, 500);

        await controller.resetOffsets(source: 'test_reset');
        stored = await prefs.getForProfile('profile-a');
        expect(stored, PlaybackSyncOffsets.defaults);
      },
    );

    test('setters keep clamp invariants through preferences model', () async {
      final storage = _MemorySecureStorage();
      final prefs = await PlaybackSyncOffsetPreferences.create(
        storage: storage,
      );
      final container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(GetIt.asNewInstance()),
          selectedProfileIdProvider.overrideWithValue('profile-a'),
          playbackSyncOffsetPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(prefs.dispose);

      final controller = container.read(playbackSyncOffsetControllerProvider);
      await controller.setSubtitleOffsetMs(999999, source: 'test_clamp');
      await controller.setAudioOffsetMs(-999999, source: 'test_clamp');

      final stored = await prefs.getForProfile('profile-a');
      expect(stored.subtitleOffsetMs, PlaybackSyncOffsets.maxOffsetMs);
      expect(stored.audioOffsetMs, PlaybackSyncOffsets.minOffsetMs);
    });

    test(
      'rapid preset updates complete without timeout (perf smoke)',
      () async {
        final storage = _MemorySecureStorage();
        final prefs = await PlaybackSyncOffsetPreferences.create(
          storage: storage,
        );
        final container = ProviderContainer(
          overrides: [
            slProvider.overrideWithValue(GetIt.asNewInstance()),
            selectedProfileIdProvider.overrideWithValue('profile-a'),
            playbackSyncOffsetPreferencesProvider.overrideWithValue(prefs),
          ],
        );
        addTearDown(container.dispose);
        addTearDown(prefs.dispose);

        final controller = container.read(playbackSyncOffsetControllerProvider);
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 100; i++) {
          final value =
              PlaybackSyncOffsetController.quickPresetValuesMs[i %
                  PlaybackSyncOffsetController.quickPresetValuesMs.length];
          await controller.applyPresetMs(value, source: 'perf_smoke');
        }
        stopwatch.stop();

        // Garde anti-régression grossière, sans micro-benchmark flaky.
        expect(stopwatch.elapsedMilliseconds < 5000, isTrue);
      },
    );
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
