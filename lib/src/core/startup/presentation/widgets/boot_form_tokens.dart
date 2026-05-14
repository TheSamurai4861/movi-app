import 'package:flutter/material.dart';

/// Mesures et styles alignés Figma boot (frame ~393×852, Phase 4 étape 1).
///
/// Aucun effet sur les écrans qui n’appliquent pas explicitement ces helpers :
/// pas de changement global de thème.
abstract final class BootFormTokens {
  static const double _mobileBreakpoint = 600;
  static const double _mobileHorizontalPagePadding = 20;

  /// Largeur max bouton principal alignée sur les champs.
  static const double primaryActionMaxWidth = textFieldMaxWidth;

  /// Hauteur bouton principal (Figma 50).
  static const double primaryActionHeight = 50;

  /// Largeur max champ (desktop/tablette).
  static const double textFieldMaxWidth = 380;

  /// Hauteur visée champ (Figma 50 pour la zone saisie).
  static const double textFieldMinHeight = 50;

  /// Rayon boutons / champs (Figma 25).
  static const double borderRadius = 25;

  /// Espacement vertical standard entre éléments de formulaire boot.
  static const double formElementGap = 16;

  /// Limite la largeur d'un champ.
  ///
  /// Sur mobile, le champ peut aller jusqu'à `screenWidth - 40`
  /// (20px de marge horizontale de chaque côté).
  static Widget constrainTextField(
    Widget child, {
    bool alignLeft = false,
  }) {
    return LayoutBuilder(
      builder: (context, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isMobile = screenWidth <= _mobileBreakpoint;
        final mobileMaxWidth = screenWidth - (_mobileHorizontalPagePadding * 2);
        final maxWidth = isMobile
            ? (mobileMaxWidth > 0 ? mobileMaxWidth : textFieldMaxWidth)
            : textFieldMaxWidth;

        final constrained = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        );

        if (alignLeft) {
          return Align(alignment: Alignment.centerLeft, child: constrained);
        }
        return Center(child: constrained);
      },
    );
  }

  /// Limite la largeur d'un bouton d'action principal.
  ///
  /// Sur mobile, le bouton peut aller jusqu'à `screenWidth - 40`
  /// (20px de marge horizontale de chaque côté).
  static Widget constrainPrimaryAction(Widget child) {
    return LayoutBuilder(
      builder: (context, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isMobile = screenWidth <= _mobileBreakpoint;
        final mobileMaxWidth = screenWidth - (_mobileHorizontalPagePadding * 2);
        final maxWidth = isMobile
            ? (mobileMaxWidth > 0 ? mobileMaxWidth : primaryActionMaxWidth)
            : primaryActionMaxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        );
      },
    );
  }

  /// Style [FilledButton] pour actions boot (recovery, etc.).
  static ButtonStyle bootPrimaryButtonStyle(ThemeData theme) {
    final scheme = theme.colorScheme;
    return FilledButton.styleFrom(
      minimumSize: const Size(48, primaryActionHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return scheme.onPrimary;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.surfaceContainerHighest;
        }
        return scheme.primary;
      }),
    );
  }

  /// [InputDecoration] de base pour [AppLabeledTextField] sur pages boot
  /// (auth / source / profil) : `decoration: BootFormTokens.bootTextFieldDecoration(theme)`.
  static InputDecoration bootTextFieldDecoration(ThemeData theme) {
    final scheme = theme.colorScheme;
    final r = BorderRadius.circular(borderRadius);
    final fill = scheme.surfaceContainerHighest;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(borderRadius: r, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: scheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide.none,
      ),
    );
  }
}
