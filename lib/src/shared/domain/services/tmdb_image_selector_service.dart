/// Utility service to pick the best TMDB image variants for posters and logos.
///
/// Rules:
/// - Poster: no-language -> en -> highest vote_average.
/// - Logo: preferred language -> en -> no-language -> highest vote_average,
///   preferring wide logos (ratio >= 2.0).
class TmdbImageSelectorService {
  const TmdbImageSelectorService._();

  /// Select the best `file_path` for a poster.
  static String? selectPosterPath(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final List<Map<String, dynamic>> list = posters
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

    final List<Map<String, dynamic>> noLang =
        list.where((m) => m['iso_639_1'] == null).toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final List<Map<String, dynamic>> en =
        list
            .where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en'))
            .toList()
          ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  /// Select the best `file_path` for a logo.
  ///
  /// [preferredLang] is an ISO 639-1 code (for example `fr` from `fr-FR`).
  /// Priority is PNG first, then SVG fallback, with the same language order.
  static String? selectLogoPath(List<dynamic> logos, {String? preferredLang}) {
    if (logos.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    double ratioOf(Map<String, dynamic> m) {
      final w = m['width'];
      final h = m['height'];
      final dw = (w is num)
          ? w.toDouble()
          : double.tryParse(w?.toString() ?? '') ?? 0;
      final dh = (h is num)
          ? h.toDouble()
          : double.tryParse(h?.toString() ?? '') ?? 0;
      if (dw <= 0 || dh <= 0) return 0;
      return dw / dh;
    }

    final List<Map<String, dynamic>> list = logos
        .whereType<Map<String, dynamic>>()
        .where((m) => m['file_path'] != null)
        .toList();
    if (list.isEmpty) return null;

    List<Map<String, dynamic>> sortByScore(List<Map<String, dynamic>> l) =>
        (l..sort((a, b) => scoreOf(b).compareTo(scoreOf(a))));

    List<Map<String, dynamic>> preferWide(List<Map<String, dynamic>> l) {
      final wide = l.where((m) => ratioOf(m) >= 2.0).toList();
      if (wide.isNotEmpty) return sortByScore(wide);
      return sortByScore(l);
    }

    final pref = (preferredLang ?? '').split('-').first.toLowerCase().trim();

    bool isPng(Map<String, dynamic> m) {
      final p = pathOf(m)?.toLowerCase() ?? '';
      return p.endsWith('.png');
    }

    bool isSvg(Map<String, dynamic> m) {
      final p = pathOf(m)?.toLowerCase() ?? '';
      return p.endsWith('.svg');
    }

    String? pickLangByFormat(
      String? iso639,
      bool Function(Map<String, dynamic>) formatFilter,
    ) {
      final List<Map<String, dynamic>> filtered;
      if (iso639 == null) {
        filtered = list.where((m) {
          final s = m['iso_639_1']?.toString().trim();
          return s == null || s.isEmpty;
        }).toList();
      } else {
        final iso = iso639.toLowerCase();
        filtered = list
            .where((m) => m['iso_639_1']?.toString().toLowerCase() == iso)
            .toList();
      }
      final typed = filtered.where(formatFilter).toList();
      if (typed.isEmpty) return null;
      final picked = preferWide(typed);
      return picked.isEmpty ? null : pathOf(picked.first);
    }

    if (pref.isNotEmpty) {
      final p = pickLangByFormat(pref, isPng);
      if (p != null) return p;
    }

    final enPick = pickLangByFormat('en', isPng);
    if (enPick != null) return enPick;

    final noLangPick = pickLangByFormat(null, isPng);
    if (noLangPick != null) return noLangPick;

    if (pref.isNotEmpty) {
      final p = pickLangByFormat(pref, isSvg);
      if (p != null) return p;
    }

    final enSvgPick = pickLangByFormat('en', isSvg);
    if (enSvgPick != null) return enSvgPick;

    final noLangSvgPick = pickLangByFormat(null, isSvg);
    if (noLangSvgPick != null) return noLangSvgPick;

    final anyPng = list.where(isPng).toList();
    if (anyPng.isNotEmpty) {
      return pathOf(sortByScore(anyPng).first);
    }

    final anySvg = list.where(isSvg).toList();
    if (anySvg.isNotEmpty) {
      return pathOf(sortByScore(anySvg).first);
    }

    return null;
  }
}
