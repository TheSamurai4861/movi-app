import 'package:flutter/material.dart';

/// Palette de couleurs proposÃƒÆ’Ã‚Â©e pour les profils.
///
/// IMPORTANT (clean arch / pro):
/// - Ce fichier est dans `presentation/ui` car c'est une constante purement UI.
/// - Ne pas mettre ce genre de constantes dans des providers/controllers.
const List<(Color color, String name)> profileColorOptions = [
  (Color(0xFF2160AB), 'Blue'),
  (Color(0xFF9C27B0), 'Purple'),
  (Color(0xFFE91E63), 'Pink'),
  (Color(0xFFFF5722), 'Orange'),
  (Color(0xFFFFC107), 'Amber'),
  (Color(0xFF4CAF50), 'Green'),
  (Color(0xFF00BCD4), 'Cyan'),
  (Color(0xFF607D8B), 'Blue Grey'),
];
