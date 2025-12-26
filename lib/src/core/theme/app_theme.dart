import 'package:flutter/material.dart';

import 'package:movi/src/core/theme/app_colors.dart';

/// Définit les thèmes clair/sombre de l'application Movi.
///
/// Utilise Material 3 (`useMaterial3: true`) avec un `ColorScheme.fromSeed`
/// basé sur une couleur d'accent configurable. Les palettes Movi (fond,
/// surfaces, textes) sont ensuite réintroduites via [AppColors] pour
/// garder une identité visuelle forte.
class AppTheme {
  const AppTheme._();

  /// Thème sombre Movi.
  static ThemeData dark({Color? accentColor}) =>
      _buildTheme(Brightness.dark, accentColor: accentColor);

  /// Thème clair Movi.
  static ThemeData light({Color? accentColor}) =>
      _buildTheme(Brightness.light, accentColor: accentColor);

  /// Construit un [ThemeData] complet à partir d'une [Brightness]
  /// et d'une couleur d'accent optionnelle.
  static ThemeData _buildTheme(Brightness brightness, {Color? accentColor}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = _buildColorScheme(
      isDark: isDark,
      accentColor: accentColor,
    );

    final textTheme = _buildTextTheme(isDark: isDark);

    // Couleurs "globales" dérivées
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final primaryTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final surfaceContainer = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;

    // Styles communs aux boutons principaux
    final buttonTextStyle = textTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 15);
    const buttonShape = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // Désactivation volontaire des effets de splash/hover par défaut
      // pour garder une esthétique plus "ciné/app TV".
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,

      scaffoldBackgroundColor: backgroundColor,

      textTheme: textTheme,

      // ────────────── AppBar ──────────────
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: primaryTextColor),
      ),

      // ────────────── Card ───────────────
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        elevation: isDark ? 0 : 1,
      ),

      // ────────────── ListTile ───────────
      listTileTheme: ListTileThemeData(
        iconColor: primaryTextColor,
        textColor: primaryTextColor,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ────────────── Chip ───────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: secondaryTextColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        selectedColor: colorScheme.primary.withValues(alpha: 0.12),
        secondarySelectedColor: colorScheme.primary.withValues(alpha: 0.2),
      ),

      // ────────────── Input / TextField ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ────────────── Icones ─────────────
      iconTheme: IconThemeData(color: primaryTextColor, size: 24),

      // ────────────── Boutons ────────────
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(
          colorScheme: colorScheme,
          textStyle: buttonTextStyle,
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(
          colorScheme: colorScheme,
          textStyle: buttonTextStyle,
          padding: buttonPadding,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: buttonTextStyle,
          overlayColor: Colors.transparent,
        ),
      ),

      // ────────────── Divider ────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 32,
      ),

      // ────────────── Checkbox ───────────
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return surfaceContainer;
        }),
        checkColor: WidgetStateProperty.all<Color>(colorScheme.onPrimary),
      ),

      // ────────────── SnackBar ───────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        actionTextColor: colorScheme.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: primaryTextColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Construit le [ColorScheme] de base à partir d'un seed et de la palette Movi.
  static ColorScheme _buildColorScheme({
    required bool isDark,
    Color? accentColor,
  }) {
    final effectiveAccentColor = accentColor ?? AppColors.accent;

    final base = ColorScheme.fromSeed(
      brightness: isDark ? Brightness.dark : Brightness.light,
      seedColor: effectiveAccentColor,
    );

    final surface = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surfaceHigh = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceHighest = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;
    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return base.copyWith(
      primary: effectiveAccentColor,
      onPrimary: Colors.white,
      surface: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      onSurface: primaryText,
      onSurfaceVariant: secondaryText,
      outline: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFBFC4CC),
      outlineVariant: isDark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFE0E3E8),
      inversePrimary: const Color(0xFF9CC4FF),
      surfaceTint: effectiveAccentColor,
    );
  }

  /// Construit la [TextTheme] Movi basée sur Montserrat.
  static TextTheme _buildTextTheme({required bool isDark}) {
    // Base : Montserrat appliqué au textTheme matériel par défaut.
    final base = isDark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    final primary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    TextStyle headline(double size) =>
        (base.titleLarge ?? const TextStyle()).copyWith(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.2,
          decoration: TextDecoration.none,
          decorationColor: null,
        );

    TextStyle body(double size, FontWeight weight, Color color) =>
        (base.bodyMedium ?? const TextStyle()).copyWith(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.4,
          decoration: TextDecoration.none,
          decorationColor: null,
        );

    return base.copyWith(
      headlineSmall: headline(24),
      titleLarge: headline(20),
      titleMedium: headline(18),
      bodyLarge: body(16, FontWeight.w500, primary),
      bodyMedium: body(14, FontWeight.w500, secondary),
      bodySmall: body(12, FontWeight.w400, secondary),
      labelLarge: body(16, FontWeight.w600, primary),
      labelMedium: body(14, FontWeight.w500, secondary),
      labelSmall: body(12, FontWeight.w500, secondary),
    );
  }

  /// Style de base pour les boutons principaux (Filled / Elevated).
  static ButtonStyle _primaryButtonStyle({
    required ColorScheme colorScheme,
    required TextStyle? textStyle,
    required EdgeInsetsGeometry padding,
    required OutlinedBorder shape,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: padding,
      shape: shape,
      textStyle: textStyle,
      overlayColor: Colors.transparent,
    );
  }
}
