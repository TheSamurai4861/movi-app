import 'package:flutter/material.dart';

/// Palette centrale de l'application Movi.
///
/// Sert de base pour construire les thèmes clair/sombre,
/// tout en laissant la place à une couleur d'accent dynamique.
class AppColors {
  const AppColors._();

  // Couleur d'accent principale (utilisée comme seed Material 3).
  static const Color accent = Color(0xFF2160AB);

  // Palette sombre
  static const Color darkBackground = Color.fromRGBO(20, 20, 20, 1);
  static const Color secondaryDarkBackground = Color.fromRGBO(40, 40, 40, 1);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF1C1C1C);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA6A6A6);

  // Palette claire
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF3F5F8);
  static const Color lightSurfaceVariant = Color(0xFFE7EAF0);
  static const Color lightTextPrimary = Color(0xFF141414);
  static const Color lightTextSecondary = Color(0xFF4F4F4F);
}
