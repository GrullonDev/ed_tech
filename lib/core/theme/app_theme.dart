import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

/// Tokens de diseño "Kinetic Cyber-Tribe" (rediseño hecho en Stitch,
/// proyecto "Racha Tribu UI Redesign" — ver el `designMd` completo del
/// proyecto para el detalle de cada componente): estética futurista
/// glassmórfica de e-sports — fondos de vacío profundo, tarjetas
/// translúcidas con blur, y tres acentos bioluminiscentes (fuego para
/// rachas, ultravioleta para la tribu, cian para analítica/ranking).
///
/// Reemplaza la paleta clara original ("Kinship Routine") pisando los
/// mismos nombres de campo a propósito, para que las ~170 referencias a
/// `AppColors.*` ya existentes en las pantallas tomen el nuevo look sin
/// tener que tocar cada archivo uno por uno.
abstract final class AppColors {
  // Fuego eléctrico: motor de rachas — check-ins, momentum, progreso.
  static const primary = Color(0xFFFF5722);
  static const primaryContainer = Color(0xFFFF7A00);
  static const onPrimary = Color(0xFFFFFFFF);

  // Ultravioleta neón: identidad de tribu/círculo, camaradería social.
  static const secondary = Color(0xFF8A2BE2);
  static const secondaryContainer = Color(0xFF9D4EDD);
  static const onSecondary = Color(0xFFFFFFFF);

  // Cian cyber: analítica en vivo, delta de ranking, verificación.
  static const tertiary = Color(0xFF00F0FF);
  static const onTertiary = Color(0xFF00363A);

  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);

  static const background = Color(0xFF0B0D17); // Void Obsidian
  static const surface = Color(0xFF131726); // Abyssal Slate
  static const surfaceContainer = Color(0xFF1A1F36); // Orbital Surface

  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFF94A3B8); // Starlight Grey
  static const outline = Color(0xFF475569); // Muted Nebula
  static const outlineWhisper = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  static const streakGlow = Color(0x59FF5722); // Aura glow "Streak Ignition"
  static const completedGlow = Color(0x5900F0FF); // Aura glow "Cyber Apex"

  static const lavenderContainer = Color(0xFF241B3A); // glass ultravioleta
  static const warningContainer = Color(0xFF3A2410); // glass ámbar
  static const celebrationStart = Color(0x40FFD700); // shimmer dorado
  static const celebrationEnd = Color(0x14FFD700);

  static const rankGold = Color(0xFFFFD700);
  static const rankSilver = Color(0xFFE2E8F0);
  static const rankBronze = Color(0xFFCD7F32);
  static const rankMythic = Color(0xFFC084FC);
}

/// Paleta clara original ("Kinship Routine"), conservada para poder volver
/// atrás fácilmente si el rediseño de Stitch no se termina adoptando.
abstract final class LegacyLightColors {
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

/// Envuelve contenido con un ancho máximo y lo centra, para que las
/// pantallas no se estiren en exceso en móviles grandes/tablets en modo
/// retrato, manteniendo la app responsiva en todos los tamaños de teléfono.
/// Centra el contenido y limita su ancho para que la app se vea bien tanto
/// en teléfonos angostos como en tablets/pantallas grandes: en vez de un tope
/// fijo, [maxWidth] escala con el ancho disponible dentro de un rango
/// razonable (móvil ≈ 480, tablet ≈ 720).
class AppMaxWidth extends StatelessWidget {
  const AppMaxWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveMaxWidth =
        maxWidth ?? (screenWidth * 0.9).clamp(320, 720).toDouble();
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  // Aura glow "Streak Ignition" del design system de Stitch.
  static const streak = [
    BoxShadow(color: Color(0x59FF5722), blurRadius: 32, offset: Offset(0, 8)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final bodyTextTheme = GoogleFonts.outfitTextTheme(base.textTheme);

    final colorScheme = const ColorScheme.dark().copyWith(
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
      textTheme: bodyTextTheme.apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer.withValues(alpha: 0.85),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.outlineWhisper),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.outlineWhisper),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
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
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.05,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceContainer,
        selectedColor: AppColors.tertiary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.outlineWhisper),
        ),
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    final colorScheme = const ColorScheme.light().copyWith(
      primary: LegacyLightColors.primary,
      onPrimary: LegacyLightColors.onPrimary,
      primaryContainer: LegacyLightColors.primaryContainer,
      secondary: LegacyLightColors.secondary,
      onSecondary: LegacyLightColors.onSecondary,
      secondaryContainer: LegacyLightColors.secondaryContainer,
      tertiary: LegacyLightColors.tertiary,
      onTertiary: LegacyLightColors.onTertiary,
      error: LegacyLightColors.error,
      onError: LegacyLightColors.onError,
      surface: LegacyLightColors.surface,
      onSurface: LegacyLightColors.onSurface,
      onSurfaceVariant: LegacyLightColors.onSurfaceVariant,
      outline: LegacyLightColors.outline,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LegacyLightColors.background,
      textTheme: textTheme.apply(
        bodyColor: LegacyLightColors.onSurface,
        displayColor: LegacyLightColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LegacyLightColors.background,
        foregroundColor: LegacyLightColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: LegacyLightColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: LegacyLightColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: LegacyLightColors.outlineWhisper),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LegacyLightColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: LegacyLightColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LegacyLightColors.primary,
          foregroundColor: LegacyLightColors.onPrimary,
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
