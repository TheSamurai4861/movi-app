/// Points de rupture (breakpoints) pour la détection du type d'écran.
///
/// Ces valeurs définissent les seuils de largeur d'écran pour déterminer
/// le type d'écran (mobile, tablet, desktop, tv).
class Breakpoints {
  Breakpoints._();

  /// Largeur maximale pour un écran mobile (en pixels logiques).
  static const double mobileMax = 600;

  /// Largeur maximale pour une tablette (en pixels logiques).
  static const double tabletMax = 1024;

  /// Largeur maximale pour un écran desktop (en pixels logiques).
  static const double desktopMax = 1920;

  /// Ratio largeur/hauteur minimum pour considérer un écran comme TV.
  ///
  /// Un écran avec un ratio >= 16/9 et une largeur > desktopMax est considéré comme TV.
  static const double tvAspectRatio = 16 / 9;
}

