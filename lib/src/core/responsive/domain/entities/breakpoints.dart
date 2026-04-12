/// Breakpoints utilises pour classifier le type d'ecran.
class Breakpoints {
  Breakpoints._();

  /// Plus petit cote maximal pour un ecran mobile (pixels logiques).
  static const double mobileMax = 600;

  /// Plus petit cote maximal pour la bande tablette (pixels logiques).
  ///
  /// Regles metier pour `600 < shortestSide <= 900`:
  /// - Android/iOS: paysage => TV, portrait/carre => mobile
  /// - Desktop non-Windows: desktop
  static const double tabletMaxShortestSide = 900;

  /// Largeur maximale pour un ecran desktop (pixels logiques).
  static const double desktopMax = 1920;

  /// Ratio largeur/hauteur minimal pour considerer un ecran comme TV.
  static const double tvAspectRatio = 16 / 9;

  /// Plus petit cote minimal (pixels logiques) pour classer en TV.
  static const double tvMinShortestSide = 500;

  /// Plus grand cote minimal (pixels logiques) pour classer en TV.
  static const double tvMinLongestSide = 900;
}
