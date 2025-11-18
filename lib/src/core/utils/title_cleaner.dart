/// Utilitaire pour nettoyer les titres de films/séries en enlevant les patterns
/// non pertinents comme |FR|, (Multi), etc.
class TitleCleaner {
  TitleCleaner._();

  /// Patterns à supprimer du titre (entre parenthèses, crochets, pipes, etc.)
  static final RegExp _patternToRemove = RegExp(
    r'\s*[|]\s*[A-Z]{2,}\s*[|]?' // |FR|, |EN|, etc.
    r'|\s*\([^)]*\)' // (Multi), (VOSTFR), etc.
    r'|\s*\[[^\]]*\]' // [HD], [4K], etc.
    r'|\s*-\s*[A-Z]{2,}$' // -FR, -EN à la fin
    r'|\s*\([^)]*VOST[^)]*\)' // (VOSTFR), (VOST), etc.
    r'|\s*\([^)]*VF[^)]*\)' // (VF), (VFQ), etc.
    r'|\s*\([^)]*VO[^)]*\)', // (VO), (VOF), etc.
    caseSensitive: false,
  );

  /// Nettoie un titre en enlevant les patterns non pertinents
  static String clean(String title) {
    if (title.isEmpty) return title;

    var cleaned = title.trim();

    // Supprimer les patterns répétitifs jusqu'à ce qu'il n'y en ait plus
    var previous = '';
    while (previous != cleaned) {
      previous = cleaned;
      cleaned = cleaned.replaceAll(_patternToRemove, '').trim();
    }

    // Nettoyer les espaces multiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Nettoie un titre et retourne aussi l'année si elle est présente
  static ({String cleanedTitle, int? year}) cleanWithYear(String title) {
    final cleaned = clean(title);

    // Extraire l'année à la fin (format: "Titre (2020)" ou "Titre 2020")
    final yearMatch = RegExp(r'\s*\(?(\d{4})\)?\s*$').firstMatch(cleaned);
    if (yearMatch != null) {
      final yearStr = yearMatch.group(1);
      final year = int.tryParse(yearStr ?? '');
      if (year != null && year >= 1900 && year <= 2100) {
        final titleWithoutYear = cleaned
            .substring(0, yearMatch.start)
            .trim()
            .replaceAll(RegExp(r'[()]'), '')
            .trim();
        return (cleanedTitle: titleWithoutYear, year: year);
      }
    }

    return (cleanedTitle: cleaned, year: null);
  }
}
