import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movi/src/features/player/domain/value_objects/video_fit_mode.dart';

/// Persisted player preferences (audio and subtitle languages) with change notifications.
class PlayerPreferences {
  PlayerPreferences._({
    required FlutterSecureStorage storage,
    required String audioLanguageStorageKey,
    required String? preferredAudioLanguage,
    required StreamController<String?> audioLanguageController,
    required String subtitleLanguageStorageKey,
    required String? preferredSubtitleLanguage,
    required StreamController<String?> subtitleLanguageController,
    required String videoFitModeStorageKey,
    required VideoFitMode? preferredVideoFitMode,
    required StreamController<String?> videoFitModeController,
  }) : _storage = storage,
       _audioLanguageStorageKey = audioLanguageStorageKey,
       _preferredAudioLanguage = preferredAudioLanguage,
       _audioLanguageController = audioLanguageController,
       _subtitleLanguageStorageKey = subtitleLanguageStorageKey,
       _preferredSubtitleLanguage = preferredSubtitleLanguage,
       _subtitleLanguageController = subtitleLanguageController,
       _videoFitModeStorageKey = videoFitModeStorageKey,
       _preferredVideoFitMode = preferredVideoFitMode,
       _videoFitModeController = videoFitModeController;

  static const String _defaultAudioLanguageStorageKey =
      'prefs.player_preferred_audio_language';
  static const String _defaultSubtitleLanguageStorageKey =
      'prefs.player_preferred_subtitle_language';
  static const String _defaultVideoFitModeStorageKey =
      'prefs.player_preferred_video_fit_mode';

  /// Builds a preferences instance by reading the persisted values from storage.
  static Future<PlayerPreferences> create({
    FlutterSecureStorage? storage,
    String? defaultAudioLanguage,
    String audioLanguageStorageKey = _defaultAudioLanguageStorageKey,
    String? defaultSubtitleLanguage,
    String subtitleLanguageStorageKey = _defaultSubtitleLanguageStorageKey,
    VideoFitMode? defaultVideoFitMode,
    String videoFitModeStorageKey = _defaultVideoFitModeStorageKey,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();

    final persistedAudioRaw = await resolvedStorage.read(
      key: audioLanguageStorageKey,
    );
    final persistedAudio = _normalizeLanguageCode(persistedAudioRaw);
    final initialAudio = persistedAudio ?? defaultAudioLanguage;

    final persistedSubtitleRaw = await resolvedStorage.read(
      key: subtitleLanguageStorageKey,
    );
    final persistedSubtitle = _normalizeLanguageCode(persistedSubtitleRaw);
    final initialSubtitle = persistedSubtitle ?? defaultSubtitleLanguage;

    final persistedVideoFitModeRaw = await resolvedStorage.read(
      key: videoFitModeStorageKey,
    );
    final persistedVideoFitMode = VideoFitMode.fromValue(persistedVideoFitModeRaw);
    final initialVideoFitMode = persistedVideoFitMode ?? defaultVideoFitMode ?? VideoFitMode.contain;

    return PlayerPreferences._(
      storage: resolvedStorage,
      audioLanguageStorageKey: audioLanguageStorageKey,
      preferredAudioLanguage: initialAudio,
      audioLanguageController: StreamController<String?>.broadcast(),
      subtitleLanguageStorageKey: subtitleLanguageStorageKey,
      preferredSubtitleLanguage: initialSubtitle,
      subtitleLanguageController: StreamController<String?>.broadcast(),
      videoFitModeStorageKey: videoFitModeStorageKey,
      preferredVideoFitMode: initialVideoFitMode,
      videoFitModeController: StreamController<String?>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _audioLanguageStorageKey;
  final StreamController<String?> _audioLanguageController;
  String? _preferredAudioLanguage;
  final String _subtitleLanguageStorageKey;
  final StreamController<String?> _subtitleLanguageController;
  String? _preferredSubtitleLanguage;
  final String _videoFitModeStorageKey;
  final StreamController<String?> _videoFitModeController;
  VideoFitMode? _preferredVideoFitMode;

  /// Currently selected preferred audio language (null = use system default).
  String? get preferredAudioLanguage => _preferredAudioLanguage;

  /// Stream emitting whenever the preferred audio language changes.
  Stream<String?> get preferredAudioLanguageStream =>
      _audioLanguageController.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<String?> get preferredAudioLanguageStreamWithInitial async* {
    yield _preferredAudioLanguage;
    yield* _audioLanguageController.stream;
  }

  /// Currently selected preferred subtitle language (null = disabled).
  String? get preferredSubtitleLanguage => _preferredSubtitleLanguage;

  /// Stream emitting whenever the preferred subtitle language changes.
  Stream<String?> get preferredSubtitleLanguageStream =>
      _subtitleLanguageController.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<String?> get preferredSubtitleLanguageStreamWithInitial async* {
    yield _preferredSubtitleLanguage;
    yield* _subtitleLanguageController.stream;
  }

  /// Currently selected preferred video fit mode (null = use default contain).
  VideoFitMode? get preferredVideoFitMode => _preferredVideoFitMode;

  /// Stream emitting whenever the preferred video fit mode changes.
  Stream<String?> get preferredVideoFitModeStream =>
      _videoFitModeController.stream;

  /// Stream emitting the current value first, then subsequent changes.
  Stream<String?> get preferredVideoFitModeStreamWithInitial async* {
    yield _preferredVideoFitMode?.toValue();
    yield* _videoFitModeController.stream;
  }

  /// Persists and notifies a new preferred audio language.
  /// Pass null to use system default.
  Future<void> setPreferredAudioLanguage(String? code) async {
    final normalized = _normalizeLanguageCode(code);
    if (normalized == _preferredAudioLanguage) return;

    _preferredAudioLanguage = normalized;
    if (normalized == null || normalized.isEmpty) {
      await _storage.delete(key: _audioLanguageStorageKey);
    } else {
      await _storage.write(key: _audioLanguageStorageKey, value: normalized);
    }
    if (!_audioLanguageController.isClosed) {
      _audioLanguageController.add(normalized);
    }
  }

  /// Persists and notifies a new preferred subtitle language.
  /// Pass null to disable subtitles.
  Future<void> setPreferredSubtitleLanguage(String? code) async {
    final normalized = _normalizeLanguageCode(code);
    if (normalized == _preferredSubtitleLanguage) return;

    _preferredSubtitleLanguage = normalized;
    if (normalized == null || normalized.isEmpty) {
      await _storage.delete(key: _subtitleLanguageStorageKey);
    } else {
      await _storage.write(key: _subtitleLanguageStorageKey, value: normalized);
    }
    if (!_subtitleLanguageController.isClosed) {
      _subtitleLanguageController.add(normalized);
    }
  }

  /// Persists and notifies a new preferred video fit mode.
  Future<void> setPreferredVideoFitMode(VideoFitMode mode) async {
    if (mode == _preferredVideoFitMode) return;

    _preferredVideoFitMode = mode;
    final value = mode.toValue();
    await _storage.write(key: _videoFitModeStorageKey, value: value);
    if (!_videoFitModeController.isClosed) {
      _videoFitModeController.add(value);
    }
  }

  /// Cleans up internal resources.
  Future<void> dispose() async {
    await _audioLanguageController.close();
    await _subtitleLanguageController.close();
    await _videoFitModeController.close();
  }

  /// Normalizes a language code (trims, converts to lowercase, extracts base code).
  /// Returns null if code is null or empty.
  static String? _normalizeLanguageCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    // Intentionally keep the base language only (ISO 639) for media track matching.
    final normalized = trimmed
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;

    return normalized.isEmpty ? null : normalized;
  }
}





