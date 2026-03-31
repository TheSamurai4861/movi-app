final class DiagnosticSanitizer {
  const DiagnosticSanitizer();

  /// Filtre minimaliste: garder WARN/ERROR + lignes liées (-> error, stacktrace).
  List<String> filterAndSanitizeErrorLogs(List<String> input) {
    final kept = <String>[];

    bool keepFollowingStack = false;
    for (final rawLine in input) {
      final line = _sanitizeLine(rawLine);

      final isEventLine = line.startsWith('[') && line.contains('][');
      final isWarnOrError = line.contains('[ERROR]') || line.contains('[WARN]');
      final isErrorAttachment = line.startsWith(' -> ');

      if (isEventLine) {
        keepFollowingStack = isWarnOrError;
        if (isWarnOrError) kept.add(line);
        continue;
      }

      if (keepFollowingStack && (isErrorAttachment || _looksLikeStackLine(line))) {
        kept.add(line);
        continue;
      }
    }

    return kept;
  }

  bool _looksLikeStackLine(String line) {
    if (line.contains('#0 ') || line.contains('#1 ')) return true;
    if (line.contains('package:')) return true;
    if (line.contains('.dart:')) return true;
    return false;
  }

  String _sanitizeLine(String input) {
    var s = input;

    // Redact obvious secrets/tokens.
    s = s.replaceAll(
      RegExp(r'eyJ[a-zA-Z0-9_\-]{10,}\.[a-zA-Z0-9_\-]{10,}\.[a-zA-Z0-9_\-]{10,}'),
      '<jwt>',
    );
    s = s.replaceAll(
      RegExp(r'(SUPABASE_ANON_KEY|TMDB_API_KEY|PASSWORD|TOKEN)\s*=\s*[^ \n\r\t]+', caseSensitive: false),
      '<secret>',
    );

    // Redact urls (avoid leaking endpoints/paths).
    s = s.replaceAll(RegExp(r'https?://\S+'), '<url>');

    // Redact internal package paths (keep only package name).
    s = s.replaceAll(RegExp(r'package:movi/[^ )\n\r\t]+'), 'package:movi/<path>');

    // Redact file paths (windows + unix).
    s = s.replaceAll(RegExp(r'[A-Za-z]:\\[^ \n\r\t]+'), '<path>');
    s = s.replaceAll(RegExp(r'/(Users|home|var|opt|data)/[^ \n\r\t]+'), '<path>');

    // Trim overly long lines (avoid huge dumps).
    const max = 1000;
    if (s.length > max) {
      s = '${s.substring(0, max)}…';
    }
    return s;
  }
}

