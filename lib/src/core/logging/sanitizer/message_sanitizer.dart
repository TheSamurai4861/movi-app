class MessageSanitizer {
  MessageSanitizer({Set<String>? extraSensitiveKeys})
    : _sensitiveKeys = <String>{..._baseSensitiveKeys, ...?extraSensitiveKeys};

  static const _baseSensitiveKeys = <String>{
    'password',
    'passwd',
    'pass',
    'token',
    'authorization',
    'cookie',
    'set-cookie',
    'apikey',
    'api_key',
    'key',
    'secret',
    'client_secret',
  };
  final Set<String> _sensitiveKeys;

  // ignore: deprecated_member_use
  static final Pattern _jwtPattern = RegExp(
    r'[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+',
  );
  // ignore: deprecated_member_use
  static final Pattern _bearerPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
  );
  // ignore: deprecated_member_use
  static final Pattern _hexLongPattern = RegExp(r'\b[0-9a-fA-F]{16,}\b');
  // ignore: deprecated_member_use
  static final Pattern _base64LongPattern = RegExp(
    r'\b[A-Za-z0-9+/]{24,}={0,2}\b',
  );
  // ignore: deprecated_member_use
  static final Pattern _cookieHeaderPattern = RegExp(
    r'^(set-)?cookie:\s*.*$',
    caseSensitive: false,
    multiLine: true,
  );
  // ignore: deprecated_member_use
  static final Pattern _authHeaderPattern = RegExp(
    r'^authorization:\s*.*$',
    caseSensitive: false,
    multiLine: true,
  );

  String sanitize(String input) {
    var out = input;
    out = out.replaceAll(_jwtPattern, '****');
    out = out.replaceAll(_bearerPattern, 'Bearer ****');
    out = out.replaceAll(_hexLongPattern, '****');
    out = out.replaceAll(_base64LongPattern, '****');
    out = out.replaceAllMapped(
      _cookieHeaderPattern,
      (m) => '${m.group(0)!.split(':').first}: ****',
    );
    out = out.replaceAllMapped(
      _authHeaderPattern,
      (m) => 'Authorization: ****',
    );
    out = _maskKeyValuePairs(out);
    return out;
  }

  Map<String, Object?> sanitizeMap(Map<String, Object?> input) {
    final result = <String, Object?>{};
    for (final entry in input.entries) {
      final keyLower = entry.key.toLowerCase();
      final value = entry.value;
      if (_sensitiveKeys.contains(keyLower)) {
        result[entry.key] = '****';
      } else if (value is Map<String, Object?>) {
        result[entry.key] = sanitizeMap(value);
      } else if (value is List) {
        result[entry.key] = value.map((e) {
          if (e is Map<String, Object?>) return sanitizeMap(e);
          if (e is String) return sanitize(e);
          return e;
        }).toList();
      } else if (value is String) {
        result[entry.key] = sanitize(value);
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  String _maskKeyValuePairs(String input) {
    var out = input;
    for (final key in _sensitiveKeys) {
      // ignore: deprecated_member_use
      final keyPattern = RegExp.escape(key);
      // ignore: deprecated_member_use
      final Pattern pattern = RegExp(
        '($keyPattern)\\s*[:=]\\s*([^;\\n]+)',
        caseSensitive: false,
      );
      out = out.replaceAllMapped(pattern, (m) => '${m.group(1)}=****');
    }
    return out;
  }
}
