// Constantes de mise en page pour la feature Home.
//
// Centralise les valeurs de design pour garantir la cohérence
// et faciliter la maintenance.
import 'package:movi/src/features/home/domain/home_constants.dart';

class HomeLayoutConstants {
  HomeLayoutConstants._();

  // Dimensions des cartes média
  static const double mediaCardWidth = 150.0;
  static const double mediaCardHeight = 270.0;
  static const double mediaCardPosterHeight = 225.0;

  // Dimensions des cartes "En cours"
  static const double continueWatchingCardWidth = 300.0;
  static const double continueWatchingCardHeight = 165.0;

  // Espacements
  static const double itemSpacing = 16.0; // espace horizontal entre items
  static const double sectionGap = 32.0; // espace vertical entre sections

  // Limites et seuils
  static const int heroLimit = 20; // nombre max de films dans le hero
  static const int continueWatchingMobileLimit = 10;
  static const int continueWatchingTabletLimit = 12;
  static const int continueWatchingDesktopLimit = 14;
  static const int continueWatchingLimit = continueWatchingMobileLimit; // legacy mobile default
  static const int continueWatchingMaxLimit = continueWatchingDesktopLimit;
  static const int iptvSectionMobileLimit = HomeConstants.iptvSectionPreviewLimit;
  static const int iptvSectionTabletLimit = 12;
  static const int iptvSectionDesktopLimit = 14;
  static const int iptvSectionLimit = iptvSectionMobileLimit; // legacy mobile default
  static const int iptvSectionMaxLimit = iptvSectionDesktopLimit;

  // Héro d'accueil
  static const double heroTotalHeight = 500.0;
  static const double heroOverlayHeight = 150.0;
  static const double heroDesktopVisualBleed = 128.0;
  static const double heroDesktopFirstSectionInset = 124.0;
  static const double heroDesktopFirstSectionShieldHeight = 156.0;
  static const Duration heroRotationDuration = Duration(seconds: 9);
  static const Duration heroFadeDuration = Duration(milliseconds: 800);
  static const double heroSynopsisHeight = 80.0;

  // Seuils de progression pour "en cours"
  static const double minProgressThreshold = 0.05; // 5% minimum pour "en cours"
  static const double maxProgressThreshold = 0.95; // 95% max pour "en cours"
}
