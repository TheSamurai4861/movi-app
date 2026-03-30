class MovieVariantTitleMetadataExtractor {
  const MovieVariantTitleMetadataExtractor();

  static const Map<String, ({String code, String label})> _languageTokens =
      <String, ({String code, String label})>{
        'FR': (code: 'fr', label: 'FR'),
        'FRENCH': (code: 'fr', label: 'FR'),
        'TRUEFRENCH': (code: 'fr', label: 'FR'),
        'VF': (code: 'fr', label: 'FR'),
        'VFF': (code: 'fr', label: 'FR'),
        'VFQ': (code: 'fr', label: 'FR'),
        'EN': (code: 'en', label: 'EN'),
        'ENGLISH': (code: 'en', label: 'EN'),
      };

  MovieVariantTitleMetadata extract(String rawTitle) {
    final normalizedTitle = rawTitle.toUpperCase();

    final quality = _extractQuality(normalizedTitle);
    final dynamicRange = _extractDynamicRange(normalizedTitle);
    final audio = _extractAudioLanguage(normalizedTitle);
    final subtitle = _extractSubtitleLanguage(normalizedTitle);

    return MovieVariantTitleMetadata(
      qualityLabel: quality.$1,
      qualityRank: quality.$2,
      dynamicRangeLabel: dynamicRange,
      audioLanguageCode: audio.$1,
      audioLanguageLabel: audio.$2,
      subtitleLanguageCode: subtitle.$1,
      subtitleLanguageLabel: subtitle.$2,
      hasSubtitles: subtitle.$3,
    );
  }

  (String?, int?) _extractQuality(String normalizedTitle) {
    if (_hasAnyToken(normalizedTitle, <String>['2160P', '4K', 'UHD'])) {
      return ('4K', 4);
    }
    if (_hasAnyToken(normalizedTitle, <String>['1080P', 'FHD', 'FULLHD'])) {
      return ('Full HD', 3);
    }
    if (_hasAnyToken(normalizedTitle, <String>['720P', 'HD'])) {
      return ('HD', 2);
    }
    if (_hasAnyToken(normalizedTitle, <String>['576P', '480P', 'SD'])) {
      return ('SD', 1);
    }
    return (null, null);
  }

  String? _extractDynamicRange(String normalizedTitle) {
    if (_containsPattern(normalizedTitle, r'DOLBY[^A-Z0-9]*VISION') ||
        _hasToken(normalizedTitle, 'DV')) {
      return 'Dolby Vision';
    }
    if (_hasToken(normalizedTitle, 'HDR10+')) {
      return 'HDR10+';
    }
    if (_hasToken(normalizedTitle, 'HDR10')) {
      return 'HDR10';
    }
    if (_hasToken(normalizedTitle, 'HLG')) {
      return 'HLG';
    }
    if (_hasToken(normalizedTitle, 'HDR')) {
      return 'HDR';
    }
    return null;
  }

  (String?, String?) _extractAudioLanguage(String normalizedTitle) {
    for (final token in <String>['TRUEFRENCH', 'FRENCH', 'VF', 'VFF', 'VFQ']) {
      final language = _extractLanguageFromToken(normalizedTitle, token);
      if (language != null) {
        return (language.code, language.label);
      }
    }

    for (final token in <String>['ENGLISH', 'EN']) {
      final language = _extractLanguageFromToken(normalizedTitle, token);
      if (language != null) {
        return (language.code, language.label);
      }
    }

    if (_hasToken(normalizedTitle, 'MULTI')) {
      return (null, 'MULTI');
    }
    if (_containsPattern(normalizedTitle, r'VOST(?:FR|EN)?') ||
        _hasToken(normalizedTitle, 'VO')) {
      return (null, 'VO');
    }
    if (_hasToken(normalizedTitle, 'FR')) {
      return ('fr', 'FR');
    }
    return (null, null);
  }

  (String?, String?, bool?) _extractSubtitleLanguage(String normalizedTitle) {
    if (_containsPattern(normalizedTitle, r'VOSTFR')) {
      return ('fr', 'FR', true);
    }
    if (_containsPattern(normalizedTitle, r'VOSTEN')) {
      return ('en', 'EN', true);
    }
    if (_hasAnyToken(normalizedTitle, <String>['SUB', 'SUBS']) ||
        _containsPattern(normalizedTitle, r'VOST(?:FR|EN)?')) {
      return (null, null, true);
    }
    return (null, null, null);
  }

  ({String code, String label})? _extractLanguageFromToken(
    String normalizedTitle,
    String token,
  ) {
    if (!_hasToken(normalizedTitle, token)) {
      return null;
    }
    return _languageTokens[token];
  }

  bool _hasAnyToken(String normalizedTitle, List<String> tokens) {
    return tokens.any((token) => _hasToken(normalizedTitle, token));
  }

  bool _hasToken(String normalizedTitle, String token) {
    final pattern = '(^|[^A-Z0-9])${RegExp.escape(token)}([^A-Z0-9]|\$)';
    return RegExp(pattern).hasMatch(normalizedTitle);
  }

  bool _containsPattern(String normalizedTitle, String pattern) {
    return RegExp(
      '(^|[^A-Z0-9])$pattern([^A-Z0-9]|\$)',
    ).hasMatch(normalizedTitle);
  }
}

class MovieVariantTitleMetadata {
  const MovieVariantTitleMetadata({
    required this.qualityLabel,
    required this.qualityRank,
    required this.dynamicRangeLabel,
    required this.audioLanguageCode,
    required this.audioLanguageLabel,
    required this.subtitleLanguageCode,
    required this.subtitleLanguageLabel,
    required this.hasSubtitles,
  });

  final String? qualityLabel;
  final int? qualityRank;
  final String? dynamicRangeLabel;
  final String? audioLanguageCode;
  final String? audioLanguageLabel;
  final String? subtitleLanguageCode;
  final String? subtitleLanguageLabel;
  final bool? hasSubtitles;
}
