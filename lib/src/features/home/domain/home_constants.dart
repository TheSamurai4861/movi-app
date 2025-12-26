/// Constantes fonctionnelles liées à la feature Home.
///
/// À utiliser côté domain/data/presentation pour éviter les dépendances
/// "data -> presentation" (clean architecture).
class HomeConstants {
  HomeConstants._();

  /// Nombre d'items IPTV préchargés par section sur l'accueil.
  ///
  /// Le widget peut ensuite appliquer son propre `take()` si besoin.
  static const int iptvSectionPreviewLimit = 9;
}

