import 'dart:io';

import 'package:movi/src/core/logging/logger.dart';

class _ProxySettings {
  const _ProxySettings({
    required this.httpProxy,
    required this.httpsProxy,
    required this.noProxy,
  });

  final Uri? httpProxy;
  final Uri? httpsProxy;
  final List<String> noProxy;

  bool get isConfigured => httpProxy != null || httpsProxy != null;

  static const String _defineHttpProxy = String.fromEnvironment('HTTP_PROXY');
  static const String _defineHttpsProxy = String.fromEnvironment('HTTPS_PROXY');
  static const String _defineNoProxy = String.fromEnvironment('NO_PROXY');

  static _ProxySettings fromEnvironment() {
    final httpProxy = _parseProxyUri(_defineHttpProxy);
    final httpsProxy = _parseProxyUri(_defineHttpsProxy) ?? httpProxy;
    final noProxy = _parseNoProxy(_defineNoProxy);
    return _ProxySettings(
      httpProxy: httpProxy,
      httpsProxy: httpsProxy,
      noProxy: noProxy,
    );
  }

  static Uri? _parseProxyUri(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final candidate = value.contains('://') ? value : 'http://$value';
    final uri = Uri.tryParse(candidate);
    if (uri == null) return null;
    if (uri.host.trim().isEmpty) return null;
    final port = uri.hasPort ? uri.port : 0;
    if (port <= 0) return null;
    return uri;
  }

  static List<String> _parseNoProxy(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return const <String>[];
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}

HttpOverrides? createHttpOverridesFromEnvironment({AppLogger? logger}) {
  final settings = _ProxySettings.fromEnvironment();
  if (!settings.isConfigured) return null;
  return _ProxyHttpOverrides(settings: settings, logger: logger);
}

class _ProxyHttpOverrides extends HttpOverrides {
  _ProxyHttpOverrides({required this.settings, required this.logger});

  final _ProxySettings settings;
  final AppLogger? logger;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    client.findProxy = (uri) {
      if (_isBypassed(uri.host, settings.noProxy)) return 'DIRECT';

      final Uri? proxy = switch (uri.scheme) {
        'https' => settings.httpsProxy,
        'http' => settings.httpProxy,
        _ => null,
      };

      if (proxy == null) return 'DIRECT';
      return 'PROXY ${proxy.host}:${proxy.port}';
    };

    final credsByProxyHostPort = <String, HttpClientBasicCredentials>{};
    void registerProxyCreds(Uri proxyUri) {
      final userInfo = proxyUri.userInfo;
      if (userInfo.isEmpty) return;
      final parts = userInfo.split(':');
      final user = parts.isNotEmpty ? parts.first : '';
      final pass = parts.length >= 2 ? parts.sublist(1).join(':') : '';
      if (user.trim().isEmpty) return;
      credsByProxyHostPort['${proxyUri.host}:${proxyUri.port}'] =
          HttpClientBasicCredentials(user, pass);
    }

    if (settings.httpProxy != null) registerProxyCreds(settings.httpProxy!);
    if (settings.httpsProxy != null) registerProxyCreds(settings.httpsProxy!);

    if (credsByProxyHostPort.isNotEmpty) {
      client.authenticateProxy = (host, port, scheme, realm) async {
        final creds = credsByProxyHostPort['$host:$port'];
        if (creds == null) return false;
        client.addProxyCredentials(host, port, realm ?? '', creds);
        return true;
      };
    }

    logger?.info(
      '[network] HttpOverrides proxy enabled (http=${_mask(settings.httpProxy)}, https=${_mask(settings.httpsProxy)}, no_proxy=${settings.noProxy.length})',
      category: 'network',
    );

    return client;
  }
}

bool _isBypassed(String host, List<String> noProxy) {
  final h = host.trim().toLowerCase();
  if (h.isEmpty) return true;
  if (h == 'localhost' || h == '127.0.0.1') return true;

  for (final entry in noProxy) {
    final e = entry.trim().toLowerCase();
    if (e.isEmpty) continue;
    if (h == e) return true;
    if (e.startsWith('.') && h.endsWith(e)) return true;
    if (h.endsWith('.$e')) return true;
  }
  return false;
}

String _mask(Uri? uri) {
  if (uri == null) return '<none>';
  return '${uri.scheme}://${uri.host}:${uri.port}';
}
