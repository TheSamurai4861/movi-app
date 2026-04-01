import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@immutable
class PlaybackSyncOffsets {
  const PlaybackSyncOffsets({
    required this.subtitleOffsetMs,
    required this.audioOffsetMs,
  });

  static const int minOffsetMs = -5000;
  static const int maxOffsetMs = 5000;

  static const PlaybackSyncOffsets defaults = PlaybackSyncOffsets(
    subtitleOffsetMs: 0,
    audioOffsetMs: 0,
  );

  final int subtitleOffsetMs;
  final int audioOffsetMs;

  PlaybackSyncOffsets copyWith({int? subtitleOffsetMs, int? audioOffsetMs}) {
    return PlaybackSyncOffsets(
      subtitleOffsetMs: _clampOffset(subtitleOffsetMs ?? this.subtitleOffsetMs),
      audioOffsetMs: _clampOffset(audioOffsetMs ?? this.audioOffsetMs),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'subtitleOffsetMs': subtitleOffsetMs,
    'audioOffsetMs': audioOffsetMs,
  };

  static PlaybackSyncOffsets fromJson(
    Map<String, Object?> json, {
    PlaybackSyncOffsets fallback = defaults,
  }) {
    final subtitle = _parseOffset(
      json['subtitleOffsetMs'],
      fallback: fallback.subtitleOffsetMs,
    );
    final audio = _parseOffset(
      json['audioOffsetMs'],
      fallback: fallback.audioOffsetMs,
    );
    return PlaybackSyncOffsets(
      subtitleOffsetMs: subtitle,
      audioOffsetMs: audio,
    );
  }

  static int _parseOffset(Object? value, {required int fallback}) {
    if (value is int) return _clampOffset(value);
    if (value is num) return _clampOffset(value.round());
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return _clampOffset(parsed);
    }
    return _clampOffset(fallback);
  }

  static int _clampOffset(int value) => value.clamp(minOffsetMs, maxOffsetMs);

  @override
  bool operator ==(Object other) {
    return other is PlaybackSyncOffsets &&
        other.subtitleOffsetMs == subtitleOffsetMs &&
        other.audioOffsetMs == audioOffsetMs;
  }

  @override
  int get hashCode => Object.hash(subtitleOffsetMs, audioOffsetMs);
}

class PlaybackSyncOffsetPreferences {
  PlaybackSyncOffsetPreferences._({
    required FlutterSecureStorage storage,
    required String storageKeyPrefix,
    required StreamController<_SyncOffsetUpdate> controller,
  }) : _storage = storage,
       _storageKeyPrefix = storageKeyPrefix,
       _controller = controller;

  static const String defaultStorageKeyPrefix =
      'prefs.playback_sync_offsets.profile.';
  static const String _defaultProfileKey = '__default__';

  static Future<PlaybackSyncOffsetPreferences> create({
    FlutterSecureStorage? storage,
    String storageKeyPrefix = defaultStorageKeyPrefix,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    return PlaybackSyncOffsetPreferences._(
      storage: resolvedStorage,
      storageKeyPrefix: storageKeyPrefix,
      controller: StreamController<_SyncOffsetUpdate>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKeyPrefix;
  final StreamController<_SyncOffsetUpdate> _controller;

  Future<PlaybackSyncOffsets> getForProfile(String? profileId) async {
    final key = _buildStorageKey(profileId);
    final raw = await _storage.read(key: key);
    if (raw == null || raw.trim().isEmpty) {
      return PlaybackSyncOffsets.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _storage.write(
          key: key,
          value: jsonEncode(PlaybackSyncOffsets.defaults.toJson()),
        );
        return PlaybackSyncOffsets.defaults;
      }
      return PlaybackSyncOffsets.fromJson(decoded);
    } catch (_) {
      await _storage.write(
        key: key,
        value: jsonEncode(PlaybackSyncOffsets.defaults.toJson()),
      );
      return PlaybackSyncOffsets.defaults;
    }
  }

  Stream<PlaybackSyncOffsets> watchForProfile(String? profileId) async* {
    final scopedProfileKey = _normalizeProfileKey(profileId);
    yield await getForProfile(scopedProfileKey);
    yield* _controller.stream
        .where((event) => event.profileKey == scopedProfileKey)
        .map((event) => event.offsets);
  }

  Future<void> setForProfile(
    String? profileId,
    PlaybackSyncOffsets offsets,
  ) async {
    final scopedProfileKey = _normalizeProfileKey(profileId);
    final existing = await getForProfile(scopedProfileKey);
    if (existing == offsets) return;

    final key = _buildStorageKey(scopedProfileKey);
    await _storage.write(key: key, value: jsonEncode(offsets.toJson()));
    if (!_controller.isClosed) {
      _controller.add(
        _SyncOffsetUpdate(profileKey: scopedProfileKey, offsets: offsets),
      );
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  String _buildStorageKey(String? profileId) {
    final profileKey = _normalizeProfileKey(profileId);
    return '$_storageKeyPrefix$profileKey';
  }

  String _normalizeProfileKey(String? profileId) {
    final trimmed = profileId?.trim();
    if (trimmed == null || trimmed.isEmpty) return _defaultProfileKey;
    return trimmed;
  }
}

@immutable
class _SyncOffsetUpdate {
  const _SyncOffsetUpdate({required this.profileKey, required this.offsets});

  final String profileKey;
  final PlaybackSyncOffsets offsets;
}
