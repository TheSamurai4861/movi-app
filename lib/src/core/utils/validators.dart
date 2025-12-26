// lib/src/core/utils/validators.dart

// ignore_for_file: deprecated_member_use, duplicate_ignore

/// Vérifie grossièrement si une chaîne ressemble à une URL http(s).
/// - Tolère l’absence de schéma (ex: "example.com:8080").
/// - Ne garantit pas la joignabilité.
bool looksLikeHttpUrl(String input) {
  final v = input.trim();
  if (v.isEmpty) return false;
  // ignore: deprecated_member_use
  if (v.contains(RegExp(r'\s'))) return false;

  final hasScheme =
      v.toLowerCase().startsWith('http://') ||
      v.toLowerCase().startsWith('https://');

  final toParse = hasScheme ? v : 'http://$v';
  final uri = Uri.tryParse(toParse);
  return uri != null && (uri.host.isNotEmpty || uri.authority.isNotEmpty);
}

bool isValidIp(String input) {
  final v = input.trim();
  if (v.isEmpty) return false;
  // ignore: duplicate_ignore
  // ignore: deprecated_member_use
  final ipv4 =
      RegExp(r'^(?:\d{1,3}\.){3}\d{1,3}$').hasMatch(v) &&
      v
          .split('.')
          .every(
            (octet) => int.tryParse(octet)! >= 0 && int.tryParse(octet)! <= 255,
          );
  // ignore: deprecated_member_use
  final ipv6 = RegExp(
    r'^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|'
    r'([0-9a-fA-F]{1,4}:){1,7}:|'
    r'([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|'
    r'([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|'
    r'([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|'
    r'([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|'
    r'([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|'
    r'[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|'
    r':((:[0-9a-fA-F]{1,4}){1,7}|:)|'
    r'fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|'
    r'::(ffff(:0{1,4}){0,1}:){0,1}'
    r'(([0-9]{1,3}\.){3}[0-9]{1,3})|'
    r'([0-9a-fA-F]{1,4}:){1,4}:'
    r'(([0-9]{1,3}\.){3}[0-9]{1,3}))$',
  ).hasMatch(v);
  return ipv4 || ipv6;
}
