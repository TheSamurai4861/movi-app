typedef StreamUrlProbeResult = ({int statusCode, String? location, Object? error});

Future<StreamUrlProbeResult> probeStreamUrl(
  String url, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 6),
  bool allowBadCertificates = false,
}) async {
  return (statusCode: -1, location: null, error: 'unsupported_platform');
}

