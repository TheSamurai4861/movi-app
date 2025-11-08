import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(isDark);
    final textTheme = _buildTextTheme(isDark);

    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceContainer =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: primaryTextColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
        elevation: isDark ? 0 : 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primaryTextColor,
        textColor: primaryTextColor,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: secondaryTextColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        selectedColor: colorScheme.primary.withValues(alpha: 0.12),
        secondarySelectedColor: colorScheme.primary.withValues(alpha: 0.2),
      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      iconTheme: IconThemeData(
        color: primaryTextColor,
        size: 24,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 32,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return surfaceContainer;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        actionTextColor: colorScheme.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: primaryTextColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ColorScheme _buildColorScheme(bool isDark) {
    final base = ColorScheme.fromSeed(
      brightness: isDark ? Brightness.dark : Brightness.light,
      seedColor: AppColors.accent,
    );

    final surface = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceHigh =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceHighest =
        isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
    final primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return base.copyWith(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      surface: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      onSurface: primaryText,
      onSurfaceVariant: secondaryText,
      outline: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFBFC4CC),
      outlineVariant: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E3E8),
      inversePrimary: const Color(0xFF9CC4FF),
      surfaceTint: AppColors.accent,
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final base = GoogleFonts.montserratTextTheme();
    final primary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    TextStyle headline(double size) => GoogleFonts.montserrat(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.2,
        );

    TextStyle body(double size, FontWeight weight, Color color) =>
        GoogleFonts.montserrat(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.4,
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
}
