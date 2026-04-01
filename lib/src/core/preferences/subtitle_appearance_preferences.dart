import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SubtitleSizePreset { small, medium, large }

enum SubtitleShadowPreset { off, soft, strong }

extension SubtitleSizePresetValue on SubtitleSizePreset {
  String toValue() {
    switch (this) {
      case SubtitleSizePreset.small:
        return 'small';
      case SubtitleSizePreset.medium:
        return 'medium';
      case SubtitleSizePreset.large:
        return 'large';
    }
  }

  static SubtitleSizePreset fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'small':
        return SubtitleSizePreset.small;
      case 'large':
        return SubtitleSizePreset.large;
      case 'medium':
      default:
        return SubtitleSizePreset.medium;
    }
  }
}

extension SubtitleShadowPresetValue on SubtitleShadowPreset {
  String toValue() {
    switch (this) {
      case SubtitleShadowPreset.off:
        return 'off';
      case SubtitleShadowPreset.soft:
        return 'soft';
      case SubtitleShadowPreset.strong:
        return 'strong';
    }
  }

  static SubtitleShadowPreset fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'soft':
        return SubtitleShadowPreset.soft;
      case 'strong':
        return SubtitleShadowPreset.strong;
      case 'off':
      default:
        return SubtitleShadowPreset.off;
    }
  }
}

@immutable
class SubtitleAppearancePrefs {
  const SubtitleAppearancePrefs({
    required this.sizePreset,
    required this.textColorHex,
    required this.fontFamilyKey,
    required this.backgroundColorHex,
    required this.backgroundOpacity,
    required this.shadowPreset,
    required this.fontScale,
  });

  static const String defaultTextColorHex = '#FFFFFFFF';
  static const String defaultFontFamilyKey = 'system';
  static const String defaultBackgroundColorHex = '#FF000000';
  static const double defaultBackgroundOpacity = 0.66;
  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.30;

  static const SubtitleAppearancePrefs defaults = SubtitleAppearancePrefs(
    sizePreset: SubtitleSizePreset.medium,
    textColorHex: defaultTextColorHex,
    fontFamilyKey: defaultFontFamilyKey,
    backgroundColorHex: defaultBackgroundColorHex,
    backgroundOpacity: defaultBackgroundOpacity,
    shadowPreset: SubtitleShadowPreset.off,
    fontScale: 1.0,
  );

  final SubtitleSizePreset sizePreset;
  final String textColorHex;
  final String fontFamilyKey;
  final String backgroundColorHex;
  final double backgroundOpacity;
  final SubtitleShadowPreset shadowPreset;
  final double fontScale;

  SubtitleAppearancePrefs copyWith({
    SubtitleSizePreset? sizePreset,
    String? textColorHex,
    String? fontFamilyKey,
    String? backgroundColorHex,
    double? backgroundOpacity,
    SubtitleShadowPreset? shadowPreset,
    double? fontScale,
  }) {
    return SubtitleAppearancePrefs(
      sizePreset: sizePreset ?? this.sizePreset,
      textColorHex: textColorHex ?? this.textColorHex,
      fontFamilyKey: fontFamilyKey ?? this.fontFamilyKey,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      shadowPreset: shadowPreset ?? this.shadowPreset,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'sizePreset': sizePreset.toValue(),
    'textColorHex': textColorHex,
    'fontFamilyKey': fontFamilyKey,
    'backgroundColorHex': backgroundColorHex,
    'backgroundOpacity': backgroundOpacity,
    'shadowPreset': shadowPreset.toValue(),
    'fontScale': fontScale,
  };

  static SubtitleAppearancePrefs fromJson(
    Map<String, Object?> json, {
    SubtitleAppearancePrefs fallback = defaults,
  }) {
    final sizePreset = SubtitleSizePresetValue.fromValue(
      json['sizePreset'] as String?,
    );
    final textColorHex = _normalizeHexColor(
      json['textColorHex'] as String?,
      fallback: fallback.textColorHex,
    );
    final fontFamilyKey = _normalizeFontFamilyKey(
      json['fontFamilyKey'] as String?,
      fallback: fallback.fontFamilyKey,
    );
    final backgroundColorHex = _normalizeHexColor(
      json['backgroundColorHex'] as String?,
      fallback: fallback.backgroundColorHex,
    );
    final backgroundOpacity = _normalizeOpacity(
      json['backgroundOpacity'],
      fallback: fallback.backgroundOpacity,
    );
    final shadowPreset = SubtitleShadowPresetValue.fromValue(
      json['shadowPreset'] as String?,
    );
    final fontScale = _normalizeFontScale(
      json['fontScale'],
      fallback: fallback.fontScale,
    );
    return SubtitleAppearancePrefs(
      sizePreset: sizePreset,
      textColorHex: textColorHex,
      fontFamilyKey: fontFamilyKey,
      backgroundColorHex: backgroundColorHex,
      backgroundOpacity: backgroundOpacity,
      shadowPreset: shadowPreset,
      fontScale: fontScale,
    );
  }

  Color toTextColor() {
    return _toColor(textColorHex, fallback: const Color(0xFFFFFFFF));
  }

  double toBaseFontSize() {
    switch (sizePreset) {
      case SubtitleSizePreset.small:
        return 24;
      case SubtitleSizePreset.medium:
        return 32;
      case SubtitleSizePreset.large:
        return 40;
    }
  }

  double toFontSize() {
    final clampedScale = fontScale.clamp(minFontScale, maxFontScale);
    return toBaseFontSize() * clampedScale;
  }

  Color toBackgroundColor() {
    final color = _toColor(
      backgroundColorHex,
      fallback: const Color(0xFF000000),
    );
    final alpha = (backgroundOpacity.clamp(0.0, 1.0) * 255).round();
    return color.withAlpha(alpha);
  }

  List<Shadow>? toTextShadows() {
    switch (shadowPreset) {
      case SubtitleShadowPreset.off:
        return null;
      case SubtitleShadowPreset.soft:
        return const <Shadow>[
          Shadow(offset: Offset(1, 1), blurRadius: 2, color: Color(0xAA000000)),
        ];
      case SubtitleShadowPreset.strong:
        return const <Shadow>[
          Shadow(
            offset: Offset(1.5, 1.5),
            blurRadius: 3,
            color: Color(0xCC000000),
          ),
          Shadow(
            offset: Offset(-1, -1),
            blurRadius: 2,
            color: Color(0x66000000),
          ),
        ];
    }
  }

  TextStyle toTextStyle() {
    return TextStyle(
      height: 1.35,
      fontSize: toFontSize(),
      color: toTextColor(),
      fontFamily: resolveFontFamily(fontFamilyKey),
      backgroundColor: toBackgroundColor(),
      shadows: toTextShadows(),
    );
  }

  static String _normalizeHexColor(String? value, {required String fallback}) {
    final trimmed = value?.trim().toUpperCase();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    final withHash = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    final valid = RegExp(r'^#[A-F0-9]{8}$').hasMatch(withHash);
    return valid ? withHash : fallback;
  }

  static double _normalizeOpacity(Object? value, {required double fallback}) {
    final parsed = _toDouble(value);
    if (parsed == null) return fallback;
    return parsed.clamp(0.0, 1.0);
  }

  static double _normalizeFontScale(Object? value, {required double fallback}) {
    final parsed = _toDouble(value);
    if (parsed == null) return fallback;
    return parsed.clamp(minFontScale, maxFontScale);
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static Color _toColor(String hex, {required Color fallback}) {
    final normalized = hex.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  static String _normalizeFontFamilyKey(
    String? value, {
    required String fallback,
  }) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return fallback;
    return subtitleFontChoices.any((choice) => choice.key == normalized)
        ? normalized
        : fallback;
  }

  static String? resolveFontFamily(String key) {
    final found = subtitleFontChoices.where((choice) => choice.key == key);
    if (found.isEmpty) return null;
    return found.first.fontFamily;
  }

  static const List<SubtitleColorChoice> subtitleColorChoices =
      <SubtitleColorChoice>[
        SubtitleColorChoice(key: 'white', hex: '#FFFFFFFF'),
        SubtitleColorChoice(key: 'yellow', hex: '#FFFFEB3B'),
        SubtitleColorChoice(key: 'cyan', hex: '#FF80DEEA'),
        SubtitleColorChoice(key: 'green', hex: '#FFA5D6A7'),
      ];

  static const List<SubtitleColorChoice> subtitleBackgroundColorChoices =
      <SubtitleColorChoice>[
        SubtitleColorChoice(key: 'black', hex: '#FF000000'),
        SubtitleColorChoice(key: 'charcoal', hex: '#FF1E1E1E'),
        SubtitleColorChoice(key: 'navy', hex: '#FF0D1B2A'),
        SubtitleColorChoice(key: 'maroon', hex: '#FF3A0A0A'),
      ];

  static const List<SubtitleFontChoice> subtitleFontChoices =
      <SubtitleFontChoice>[
        SubtitleFontChoice(key: 'system', fontFamily: null),
        SubtitleFontChoice(key: 'roboto', fontFamily: 'Roboto'),
        SubtitleFontChoice(key: 'arial', fontFamily: 'Arial'),
      ];

  static const List<SubtitleShadowChoice> subtitleShadowChoices =
      <SubtitleShadowChoice>[
        SubtitleShadowChoice(key: 'off', preset: SubtitleShadowPreset.off),
        SubtitleShadowChoice(key: 'soft', preset: SubtitleShadowPreset.soft),
        SubtitleShadowChoice(
          key: 'strong',
          preset: SubtitleShadowPreset.strong,
        ),
      ];

  @override
  bool operator ==(Object other) {
    return other is SubtitleAppearancePrefs &&
        other.sizePreset == sizePreset &&
        other.textColorHex == textColorHex &&
        other.fontFamilyKey == fontFamilyKey &&
        other.backgroundColorHex == backgroundColorHex &&
        other.backgroundOpacity == backgroundOpacity &&
        other.shadowPreset == shadowPreset &&
        other.fontScale == fontScale;
  }

  @override
  int get hashCode => Object.hash(
    sizePreset,
    textColorHex,
    fontFamilyKey,
    backgroundColorHex,
    backgroundOpacity,
    shadowPreset,
    fontScale,
  );
}

@immutable
class SubtitleColorChoice {
  const SubtitleColorChoice({required this.key, required this.hex});

  final String key;
  final String hex;
}

@immutable
class SubtitleFontChoice {
  const SubtitleFontChoice({required this.key, required this.fontFamily});

  final String key;
  final String? fontFamily;
}

@immutable
class SubtitleShadowChoice {
  const SubtitleShadowChoice({required this.key, required this.preset});

  final String key;
  final SubtitleShadowPreset preset;
}

class SubtitleAppearancePreferences {
  SubtitleAppearancePreferences._({
    required FlutterSecureStorage storage,
    required String storageKeyPrefix,
    required StreamController<_SubtitleAppearanceUpdate> controller,
  }) : _storage = storage,
       _storageKeyPrefix = storageKeyPrefix,
       _controller = controller;

  static const String defaultStorageKeyPrefix =
      'prefs.subtitle_appearance.profile.';
  static const String _defaultProfileKey = '__default__';

  static Future<SubtitleAppearancePreferences> create({
    FlutterSecureStorage? storage,
    String storageKeyPrefix = defaultStorageKeyPrefix,
  }) async {
    final resolvedStorage = storage ?? const FlutterSecureStorage();
    return SubtitleAppearancePreferences._(
      storage: resolvedStorage,
      storageKeyPrefix: storageKeyPrefix,
      controller: StreamController<_SubtitleAppearanceUpdate>.broadcast(),
    );
  }

  final FlutterSecureStorage _storage;
  final String _storageKeyPrefix;
  final StreamController<_SubtitleAppearanceUpdate> _controller;

  Future<SubtitleAppearancePrefs> getForProfile(String? profileId) async {
    final key = _buildStorageKey(profileId);
    final raw = await _storage.read(key: key);
    if (raw == null || raw.trim().isEmpty) {
      return SubtitleAppearancePrefs.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _storage.write(
          key: key,
          value: jsonEncode(SubtitleAppearancePrefs.defaults.toJson()),
        );
        return SubtitleAppearancePrefs.defaults;
      }
      return SubtitleAppearancePrefs.fromJson(decoded);
    } catch (_) {
      await _storage.write(
        key: key,
        value: jsonEncode(SubtitleAppearancePrefs.defaults.toJson()),
      );
      return SubtitleAppearancePrefs.defaults;
    }
  }

  Stream<SubtitleAppearancePrefs> watchForProfile(String? profileId) async* {
    final scopedProfileKey = _normalizeProfileKey(profileId);
    yield await getForProfile(scopedProfileKey);

    yield* _controller.stream
        .where((event) => event.profileKey == scopedProfileKey)
        .map((event) => event.prefs);
  }

  Future<void> setForProfile(
    String? profileId,
    SubtitleAppearancePrefs prefs,
  ) async {
    final scopedProfileKey = _normalizeProfileKey(profileId);
    final existing = await getForProfile(scopedProfileKey);
    if (existing == prefs) return;

    final key = _buildStorageKey(scopedProfileKey);
    await _storage.write(key: key, value: jsonEncode(prefs.toJson()));
    if (!_controller.isClosed) {
      _controller.add(
        _SubtitleAppearanceUpdate(profileKey: scopedProfileKey, prefs: prefs),
      );
    }
  }

  Future<void> clearForProfile(String? profileId) async {
    final scopedProfileKey = _normalizeProfileKey(profileId);
    final key = _buildStorageKey(scopedProfileKey);
    await _storage.delete(key: key);
    if (!_controller.isClosed) {
      _controller.add(
        _SubtitleAppearanceUpdate(
          profileKey: scopedProfileKey,
          prefs: SubtitleAppearancePrefs.defaults,
        ),
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
    if (trimmed == null || trimmed.isEmpty) {
      return _defaultProfileKey;
    }
    return trimmed;
  }
}

@immutable
class _SubtitleAppearanceUpdate {
  const _SubtitleAppearanceUpdate({
    required this.profileKey,
    required this.prefs,
  });

  final String profileKey;
  final SubtitleAppearancePrefs prefs;
}
