/// src/core/config/models/network_endpoints.dart
///
/// Décrit l'ensemble des points d'accès et paramètres réseau utilisés par l'app.
/// Cette version introduit explicitement la configuration TMDB (host + version)
/// et fournit des getters résolus avec des valeurs par défaut sûres.
///
/// - Aucune clé secrète n'est codée en dur.
/// - Null-safety, API claire, champs immuables.
/// - Compatible avec les lints `flutter_lints`.
class NetworkTimeouts {
  const NetworkTimeouts({
    this.connect = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 15),
    this.send = const Duration(seconds: 10),
  });

  /// Timeout de connexion.
  final Duration connect;

  /// Timeout de réception.
  final Duration receive;

  /// Timeout d’envoi.
  final Duration send;

  NetworkTimeouts copyWith({
    Duration? connect,
    Duration? receive,
    Duration? send,
  }) {
    return NetworkTimeouts(
      connect: connect ?? this.connect,
      receive: receive ?? this.receive,
      send: send ?? this.send,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NetworkTimeouts) return false;
    return connect == other.connect &&
        receive == other.receive &&
        send == other.send;
  }

  @override
  int get hashCode => Object.hash(connect, receive, send);
}

/// Configuration des endpoints réseau de l'application.
/// - [restBaseUrl] : base URL du backend/app interne (ex: https://api.example.com)
/// - [imageBaseUrl] : base URL d'images/CDN interne
/// - [tmdbApiKey] : clé/jeton TMDB injectée via l'env (peut être v3 api_key ou v4 bearer)
/// - [tmdbBaseHost] : hôte TMDB (optionnel, par défaut api.themoviedb.org)
/// - [tmdbApiVersion] : version d'API TMDB (optionnel, par défaut "3")
class NetworkEndpoints {
  const NetworkEndpoints({
    required this.restBaseUrl,
    required this.imageBaseUrl,
    this.tmdbApiKey,
    this.tmdbBaseHost,
    this.tmdbApiVersion,
    this.timeouts = const NetworkTimeouts(),
  });

  /// Base URL principale pour les appels REST de votre backend.
  final String restBaseUrl;

  /// Base URL pour les ressources images de votre backend/CDN.
  final String imageBaseUrl;

  /// Clé/jeton TMDB (v3 ou v4). Doit être injectée via la configuration d'environnement.
  final String? tmdbApiKey;

  /// Hôte TMDB optionnel (ex: "api.themoviedb.org").
  final String? tmdbBaseHost;

  /// Version d'API TMDB optionnelle (ex: "3" ou "4").
  final String? tmdbApiVersion;

  /// Timeouts réseau.
  final NetworkTimeouts timeouts;

  /// Getter résolu : renvoie l'hôte TMDB à utiliser.
  /// Par défaut : "api.themoviedb.org".
  String get resolvedTmdbBaseHost {
    final value = tmdbBaseHost?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'api.themoviedb.org';
  }

  /// Getter résolu : renvoie la version d'API TMDB à utiliser.
  /// Par défaut : "3".
  String get resolvedTmdbApiVersion {
    final value = tmdbApiVersion?.trim();
    if (value != null && value.isNotEmpty) return value;
    return '3';
  }

  String get restBaseUrlNormalized {
    final u = restBaseUrl.trim();
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  String get imageBaseUrlNormalized {
    final u = imageBaseUrl.trim();
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  Uri get restBaseUri => Uri.parse(restBaseUrlNormalized);
  Uri get imageBaseUri => Uri.parse(imageBaseUrlNormalized);

  bool get isRestBaseUrlValid {
    final s = restBaseUri.scheme;
    return s == 'http' || s == 'https';
  }

  bool get isImageBaseUrlValid {
    final s = imageBaseUri.scheme;
    return s == 'http' || s == 'https';
  }

  NetworkEndpoints copyWith({
    String? restBaseUrl,
    String? imageBaseUrl,
    String? tmdbApiKey,
    String? tmdbBaseHost,
    String? tmdbApiVersion,
    NetworkTimeouts? timeouts,
  }) {
    return NetworkEndpoints(
      restBaseUrl: restBaseUrl ?? this.restBaseUrl,
      imageBaseUrl: imageBaseUrl ?? this.imageBaseUrl,
      tmdbApiKey: tmdbApiKey ?? this.tmdbApiKey,
      tmdbBaseHost: tmdbBaseHost ?? this.tmdbBaseHost,
      tmdbApiVersion: tmdbApiVersion ?? this.tmdbApiVersion,
      timeouts: timeouts ?? this.timeouts,
    );
  }

  String joinRestPath(String path) {
    final sanitized = path.startsWith('/') ? path.substring(1) : path;
    return restBaseUri.resolve(sanitized).toString();
  }

  String joinImagePath(String path) {
    final sanitized = path.startsWith('/') ? path.substring(1) : path;
    return imageBaseUri.resolve(sanitized).toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NetworkEndpoints) return false;
    return restBaseUrl == other.restBaseUrl &&
        imageBaseUrl == other.imageBaseUrl &&
        tmdbApiKey == other.tmdbApiKey &&
        tmdbBaseHost == other.tmdbBaseHost &&
        tmdbApiVersion == other.tmdbApiVersion &&
        timeouts == other.timeouts;
  }

  @override
  int get hashCode => Object.hash(
    restBaseUrl,
    imageBaseUrl,
    tmdbApiKey,
    tmdbBaseHost,
    tmdbApiVersion,
    timeouts,
  );
}
