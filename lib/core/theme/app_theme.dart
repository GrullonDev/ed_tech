import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de diseño de "Kinship Routine" (ver `assets/DESIGN.md`).
///
/// Centraliza colores, tipografía, radios y espaciados para que las
/// pantallas no definan estilos "a mano" sino que consuman estos tokens.
abstract final class AppColors {
  static const primary = Color(0xFF059669);
  static const primaryContainer = Color(0xFF10B981);
  static const onPrimary = Color(0xFFFFFFFF);

  static const secondary = Color(0xFFF97316);
  static const secondaryContainer = Color(0xFFF59E0B);
  static const onSecondary = Color(0xFFFFFFFF);

  static const tertiary = Color(0xFF10B981);
  static const onTertiary = Color(0xFFFFFFFF);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFF1F5F9);

  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF3D4A42);
  static const outline = Color(0xFF6D7A72);
  static const outlineWhisper = Color(0x0A0F172A);

  static const streakGlow = Color(0x59F97316);
  static const completedGlow = Color(0x3310B981);

  static const lavenderContainer = Color(0xFFEAECFB);
  static const warningContainer = Color(0xFFFFF1E6);
  static const celebrationStart = Color(0xFFE3F9EE);
  static const celebrationEnd = Color(0xFFD3F3E4);
}

abstract final class AppRadius {
  static const sm = 4.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 9999.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xl2 = 24.0;
  static const xl3 = 32.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static const streak = [
    BoxShadow(
      color: Color(0x38F97316),
      blurRadius: 28,
      offset: Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.outlineWhisper),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.01,
          ),
        ),
      ),
    );
  }
}
