// ignore_for_file: deprecated_member_use
//
// Value object représentant l'URL de base d'un serveur Stalker Portal.
// Responsable de valider l'URL saisie par l'utilisateur et de construire
// l'endpoint `/portal.php` attendu par l'API Stalker, en gérant
// les variantes fréquentes :
// - URL nue sans chemin       → `/portal.php`
// - URL contenant `/c/`       → `/c/portal.php`
// - URL contenant `/stalker_portal/c/` → `/stalker_portal/c/portal.php`
// - URL contenant déjà `portal.php` → préservée telle quelle
// Les paramètres de requête existants sont fusionnés avec ceux passés
// à `buildUri`.

import 'package:equatable/equatable.dart';

class StalkerEndpoint extends Equatable {
  const StalkerEndpoint._(this.uri);

  final Uri uri;

  static StalkerEndpoint parse(String raw) {
    final value = (raw).trim();
    final u = Uri.parse(value);
    if (!u.hasScheme || u.host.isEmpty) {
      throw FormatException('URL invalide');
    }
    return StalkerEndpoint._(u);
  }

  static StalkerEndpoint? tryParse(String raw) {
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
    
    // Si le chemin contient déjà portal.php, on le garde
    if (lower.contains('portal.php')) {
      path = raw;
    } else if (lower.contains('/stalker_portal/c/')) {
      // Chemin complet stalker_portal/c/portal.php
      path = raw.endsWith('/')
          ? '${raw}portal.php'
          : '$raw/portal.php';
    } else if (lower.contains('/c/')) {
      // Chemin /c/portal.php
      path = raw.endsWith('/')
          ? '${raw}portal.php'
          : '$raw/portal.php';
    } else if (raw.isEmpty || raw == '/') {
      // URL nue, on ajoute /portal.php
      path = '/portal.php';
    } else {
      // Chemin personnalisé, on ajoute /portal.php
      path = raw.endsWith('/')
          ? '${raw}portal.php'
          : '$raw/portal.php';
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

