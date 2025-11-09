// lib/src/core/utils/validators.dart

/// Vérifie grossièrement si une chaîne ressemble à une URL http(s).
/// - Tolère l’absence de schéma (ex: "example.com:8080").
/// - Ne garantit pas la joignabilité.
bool looksLikeHttpUrl(String input) {
  final v = input.trim();
  if (v.isEmpty) return false;
  if (v.contains(RegExp(r'\s'))) return false;

  final hasScheme = v.toLowerCase().startsWith('http://') ||
      v.toLowerCase().startsWith('https://');

  final toParse = hasScheme ? v : 'http://$v';
  final uri = Uri.tryParse(toParse);
  return uri != null && (uri.host.isNotEmpty || uri.authority.isNotEmpty);
}
