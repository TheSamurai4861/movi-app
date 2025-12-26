import 'dart:async';
import 'dart:io';

typedef StreamUrlProbeResult = ({int statusCode, String? location, Object? error});

Future<StreamUrlProbeResult> probeStreamUrl(
  String url, {
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 6),
  bool allowBadCertificates = false,
}) async {
  try {
    final uri = Uri.parse(url);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);

    if (allowBadCertificates) {
      client.badCertificateCallback = (cert, host, port) => true;
    }

    final request = await client.getUrl(uri);
    request.followRedirects = false;
    request.headers.set('Accept', '*/*');
    request.headers.set('Range', 'bytes=0-0');
    headers?.forEach((k, v) => request.headers.set(k, v));

    final response = await request.close().timeout(timeout);

    // Lire un chunk puis on ferme, pour éviter de télécharger un flux complet.
    try {
      await response.first.timeout(const Duration(seconds: 2));
    } catch (_) {}

    final status = response.statusCode;
    final location = response.headers.value(HttpHeaders.locationHeader);
    client.close(force: true);

    return (statusCode: status, location: location, error: null);
  } catch (e) {
    return (statusCode: -1, location: null, error: e);
  }
}

