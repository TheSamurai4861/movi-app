import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart';

void main() {
  test(
    'currentSelectedIptvSourceIdProvider reflects persisted source changes',
    () async {
      final prefs = _MemorySelectedIptvSourcePreferences();
      final container = ProviderContainer(
        overrides: [
          selectedIptvSourcePreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final updates = <String?>[];
      final subscription = container.listen<String?>(
        currentSelectedIptvSourceIdProvider,
        (_, next) => updates.add(next),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(subscription.read(), isNull);

      await prefs.setSelectedSourceId('source-a');

      expect(subscription.read(), 'source-a');

      await prefs.clear();

      expect(subscription.read(), isNull);
      expect(updates, containsAllInOrder(<String?>[null, 'source-a', null]));
    },
  );
}

class _MemorySelectedIptvSourcePreferences
    implements SelectedIptvSourcePreferences {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();

  String? _selectedSourceId;

  @override
  String? get selectedSourceId => _selectedSourceId;

  @override
  Stream<String?> get selectedSourceIdStream => _controller.stream;

  @override
  Stream<String?> get selectedSourceIdStreamWithInitial async* {
    yield _selectedSourceId;
    yield* _controller.stream;
  }

  @override
  Future<void> setSelectedSourceId(String? sourceId) async {
    final trimmed = sourceId?.trim();
    _selectedSourceId = trimmed == null || trimmed.isEmpty ? null : trimmed;
    _controller.add(_selectedSourceId);
  }

  @override
  Future<void> clear() => setSelectedSourceId(null);

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
