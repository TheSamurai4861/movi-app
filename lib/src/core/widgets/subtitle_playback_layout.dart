import 'package:flutter/widgets.dart';

/// Métriques partagées entre le player et l’aperçu des réglages sous-titres.
class SubtitlePlaybackLayout {
  SubtitlePlaybackLayout._();

  /// Marge basse sous les sous-titres (player). Sur téléphone les valeurs
  /// précédentes (64–96 + safe area) remontaient trop le texte.
  ///
  /// [includeDisplaySafeBottom] : mettre à `false` pour l’aperçu dans une carte
  /// (souvent déjà sous [SafeArea], le padding système ne s’applique pas pareil).
  static double bottomPadding(
    BuildContext context, {
    required bool showPlayerControls,
    bool includeDisplaySafeBottom = true,
  }) {
    final safeBottom = includeDisplaySafeBottom
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final isPhone = MediaQuery.sizeOf(context).shortestSide < 600;

    if (isPhone) {
      final base = showPlayerControls ? 44.0 : 28.0;
      return base + safeBottom;
    }

    final base = showPlayerControls ? 72.0 : 52.0;
    return base + safeBottom;
  }

  /// Facteur pour rapprocher la taille du texte de l’aperçu de celle vue en
  /// lecture plein écran (même [fontSize] logique, cadre plus petit).
  static double previewFontScale(
    BuildContext context,
    double previewVideoHeight,
  ) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final estimatedFullscreenVideoH = (size.height - padding.vertical).clamp(
      240.0,
      double.infinity,
    );
    if (previewVideoHeight <= 1) return 1.0;
    final ratio = previewVideoHeight / estimatedFullscreenVideoH;
    return ratio.clamp(0.42, 1.0);
  }
}
