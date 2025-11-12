// lib/src/core/iptv/domain/value_objects/xtream_endpoint.dart
import 'package:equatable/equatable.dart';

/// Value Object IPTV — XtreamEndpoint
/// Normalise une entrée utilisateur vers un endpoint canonique `player_api.php`.
///
/// Règles :
/// - Si le schéma est absent, on suppose `http`.
/// - Si le path est vide, "/", ou autre chose que `player_api.php`, on impose `/player_api.php`.
/// - Le port par défaut dépend du schéma (http=80, https=443).
/// - Aucune logique UI / pas de logs de credentials ici.
class XtreamEndpoint extends Equatable {
  static const String defaultPath = '/player_api.php';

  const XtreamEndpoint({
    required this.host,
    required this.port,
    this.useHttps = false,
    this.path = defaultPath,
  });

  /// Parse robuste :
  /// - tolère les entrées sans schéma (ex: "example.com:8080")
  /// - remet le path sur `/player_api.php` si besoin
  factory XtreamEndpoint.parse(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('URL vide');
    }

    // 1) Préfixe schéma si absent
    final hasScheme =
        trimmed.toLowerCase().startsWith('http://') ||
        trimmed.toLowerCase().startsWith('https://');
    final toParse = hasScheme ? trimmed : 'http://$trimmed';

    final uri = Uri.tryParse(toParse);
    if (uri == null) {
      throw const FormatException('URL invalide');
    }

    // 2) Host/authority
    if (uri.host.isEmpty && uri.authority.isEmpty) {
      throw const FormatException('Hôte manquant');
    }
    final host = uri.host.isNotEmpty
        ? uri.host
        : uri.authority.split(':').first;

    // 3) Schéma + port
    final https = uri.scheme.toLowerCase() == 'https';
    final port = uri.hasPort ? uri.port : (https ? 443 : 80);

    // 4) Path => force player_api.php
    final path =
        (uri.path.isEmpty ||
            uri.path == '/' ||
            !uri.path.endsWith('player_api.php'))
        ? defaultPath
        : (uri.path.startsWith('/') ? uri.path : '/${uri.path}');

    return XtreamEndpoint(host: host, port: port, useHttps: https, path: path);
  }

  /// Variante sûre : retourne `null` si invalide.
  static XtreamEndpoint? tryParse(String rawUrl) {
    try {
      return XtreamEndpoint.parse(rawUrl);
    } catch (_) {
      return null;
    }
  }

  final String host;
  final int port;
  final bool useHttps;
  final String path;

  bool get isDefaultPort => port == (useHttps ? 443 : 80);
  String get scheme => useHttps ? 'https' : 'http';

  /// Base sans path (inclut le port pour éviter l’ambiguïté)
  String get baseUrl => '$scheme://$host:$port';

  /// URL canonique complète (inclut path)
  String toRawUrl() => '$baseUrl${path.startsWith('/') ? path : '/$path'}';

  /// Construit une Uri avec query string (valeurs converties en String).
  Uri buildUri([Map<String, dynamic>? query]) {
    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  /// Copie immuable
  XtreamEndpoint copyWith({
    String? host,
    int? port,
    bool? useHttps,
    String? path,
  }) {
    return XtreamEndpoint(
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      path: path ?? this.path,
    );
  }

  @override
  List<Object?> get props => [host, port, useHttps, path];

  @override
  String toString() => toRawUrl();
}
