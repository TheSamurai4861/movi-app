/// Utilitaire pour nettoyer les titres de films/séries en enlevant les patterns
/// non pertinents comme |FR|, (Multi), etc.
class TitleCleaner {
  TitleCleaner._();

  /// Patterns à supprimer du titre (entre parenthèses, crochets, pipes, etc.)
  static final RegExp _pipeLangPattern = RegExp(
    r'\|\s*[A-Z]{2,}\s*\|?',
    caseSensitive: false,
  );
  static final RegExp _trailingLangPattern = RegExp(
    r'\s*-\s*[A-Z]{2,}$',
    caseSensitive: false,
  );
  static final RegExp _bracketsPattern = RegExp(
    r'\([^)]*\)|\[[^\]]*\]',
  );
  static final RegExp _separatorsPattern = RegExp(r'[|._-]+');
  static final RegExp _resolutionPattern = RegExp(
    r'^\d{3,4}P$',
    caseSensitive: false,
  );
  static final RegExp _audioChannelsPattern = RegExp(r'^\d\.\d$');
  static final RegExp _dimensionPattern = RegExp(
    r'^\d{3,4}X\d{3,4}$',
    caseSensitive: false,
  );

  static final Set<String> _noiseTokens = <String>{
    '4K',
    '8K',
    'UHD',
    'HDR',
    'HDR10',
    'DV',
    'DOLBY',
    'DOLBYVISION',
    'ATMOS',
    'TRUEHD',
    'WEB',
    'WEBDL',
    'WEBRIP',
    'BLURAY',
    'BDRIP',
    'BRRIP',
    'REMUX',
    'HDRIP',
    'CAM',
    'TS',
    'TC',
    'HD',
    'FHD',
    'MULTI',
    'VOSTFR',
    'VOST',
    'VF',
    'VFF',
    'VFQ',
    'VO',
    'VOF',
    'FRENCH',
    'ENGLISH',
    'SUB',
    'SUBS',
    'X264',
    'X265',
    'H264',
    'H265',
    'HEVC',
    'AVC',
    'AAC',
    'AC3',
    'EAC3',
    'DD',
    'DDP',
    'DTS',
    'DTSHD',
    'DTSHDMA',
    'DTSX',
    'MP3',
    'FLAC',
    '10BIT',
    '12BIT',
  };

  /// Nettoie un titre en enlevant les patterns non pertinents
  static String clean(String title) {
    if (title.isEmpty) return title;

    var cleaned = title.trim();

    // Préserver une année en parenthèses ou crochets si elle est seule.
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'[\(\[]\s*(19[9]\d|20\d{2})\s*[\)\]]'),
      (match) => ' ${match.group(1)} ',
    );

    // Supprimer les tags entre parenthèses/crochets et les langues en pipes/suffixes.
    cleaned = cleaned.replaceAll(_pipeLangPattern, ' ');
    cleaned = cleaned.replaceAll(_trailingLangPattern, ' ');
    cleaned = cleaned.replaceAll(_bracketsPattern, ' ');

    // Normaliser les séparateurs en espaces.
    cleaned = cleaned.replaceAll(_separatorsPattern, ' ');

    // Nettoyer les espaces multiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (cleaned.isEmpty) return cleaned;

    final tokens = cleaned.split(' ');
    final filtered = <String>[];

    for (final token in tokens) {
      if (_isNoiseToken(token)) continue;
      filtered.add(token);
    }

    cleaned = filtered.join(' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Nettoie un titre et retourne aussi l'année si elle est présente
  static ({String cleanedTitle, int? year}) cleanWithYear(String title) {
    final cleaned = clean(title);

    // Extraire l'année à la fin (1990-2099).
    final yearMatch = RegExp(
      r'\s*(19[9]\d|20\d{2})\s*$',
    ).firstMatch(cleaned);
    if (yearMatch != null) {
      final yearStr = yearMatch.group(1);
      final year = int.tryParse(yearStr ?? '');
      if (year != null && year >= 1990 && year <= 2099) {
        final titleWithoutYear = cleaned
            .substring(0, yearMatch.start)
            .trim()
            .replaceAll(RegExp(r'[()\[\]]'), '')
            .trim();
        return (cleanedTitle: titleWithoutYear, year: year);
      }
    }

    return (cleanedTitle: cleaned, year: null);
  }

  static bool _isNoiseToken(String token) {
    final upper = token.toUpperCase();
    if (_resolutionPattern.hasMatch(upper)) return true;
    if (_audioChannelsPattern.hasMatch(upper)) return true;
    if (_dimensionPattern.hasMatch(upper)) return true;

    final normalized = upper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalized.isEmpty) return true;

    if (normalized.startsWith('HDR')) return true;
    if (normalized == 'DV' || normalized == 'DOLBY' ||
        normalized == 'DOLBYVISION') {
      return true;
    }

    return _noiseTokens.contains(normalized);
  }
}
