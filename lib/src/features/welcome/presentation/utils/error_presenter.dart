import 'package:movi/src/core/network/network.dart';

/// Traduit un NetworkFailure en message FR court et cohérent pour l’UI.
String presentFailure(NetworkFailure f) {
  if (f is TimeoutFailure) return 'La connexion a expiré. Réessaie plus tard.';
  if (f is ConnectionFailure) return 'Impossible de se connecter au serveur.';
  if (f is UnauthorizedFailure) return 'Identifiants incorrects (401).';
  if (f is ForbiddenFailure) return 'Accès refusé (403).';
  if (f is NotFoundFailure) return 'Endpoint introuvable (404).';
  if (f is RateLimitedFailure) return 'Trop de requêtes. Réessaie plus tard.';
  if (f is ServerFailure) return 'Erreur serveur (${f.statusCode ?? ''}).';
  if (f is EmptyResponseFailure) return 'Réponse vide du serveur.';
  if (f is CancelledFailure) return 'Requête annulée.';
  return 'Erreur inconnue.';
}
