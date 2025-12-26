// ignore_for_file: deprecated_member_use
//
// Value object représentant l'URL de base d'un serveur Xtream.
// Responsable de valider l'URL saisie par l'utilisateur et de construire
// l'endpoint `player_api.php` attendu par l'API Xtream, en gérant
// les variantes fréquentes :
// - URL nue sans chemin       → `/player_api.php`
// - URL contenant `get.php`   → remplacé par `player_api.php`
// - URL contenant déjà `player_api.php` → préservée telle quelle
// Les paramètres de requête existants sont fusionnés avec ceux passés
// à `buildUri`.

import 'package:equatable/equatable.dart';

class XtreamEndpoint extends Equatable {
  const XtreamEndpoint._(this.uri);

  final Uri uri;

  static XtreamEndpoint parse(String raw) {
    final value = (raw).trim();
    final u = Uri.parse(value);
    if (!u.hasScheme || u.host.isEmpty) {
      throw FormatException('URL invalide');
    }
    return XtreamEndpoint._(u);
  }

  static XtreamEndpoint? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }

  String get host => uri.host;

  String toRawUrl() => uri.toString();

  @override
  String toString() => toRawUrl();

  Uri buildUri(Map<String, String> params) {
    final raw = uri.path;
    final lower = raw.toLowerCase();
    String path;
    if (lower.contains('player_api.php')) {
      path = raw;
    } else if (lower.contains('get.php')) {
      path = raw.replaceAll(
        RegExp('get.php', caseSensitive: false),
        'player_api.php',
      );
    } else if (raw.isEmpty) {
      path = '/player_api.php';
    } else {
      path = raw.endsWith('/') ? '${raw}player_api.php' : '$raw/player_api.php';
    }

    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: path,
      queryParameters: {...uri.queryParameters, ...params},
    );
  }

  @override
  List<Object?> get props => [uri.toString()];
}
