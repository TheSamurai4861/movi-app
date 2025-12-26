import 'package:movi/src/features/player/data/repositories/stream_url_probe_stub.dart'
    if (dart.library.io) 'stream_url_probe_io.dart' as impl;

typedef StreamUrlProbeResult = ({int statusCode, String? location, Object? error});

Future<StreamUrlProbeResult> probeStreamUrl(
  String url, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 6),
  bool allowBadCertificates = false,
}) {
  return impl.probeStreamUrl(
    url,
    headers: headers,
    timeout: timeout,
    allowBadCertificates: allowBadCertificates,
  );
}

