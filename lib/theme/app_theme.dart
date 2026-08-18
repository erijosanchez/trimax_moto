import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta Trimax — identidad corporativa azul marino + turquesa del logo.
/// Tarjetas planas sobre un fondo neutro, con el turquesa como acento único
/// de marca. Fuente única de verdad para colores.
class AppColors {
  AppColors._();

  // Chasis oscuro (headers, GPS, splash, login) — azul marino de marca.
  static const Color navy = Color(0xFF003B63);
  static const Color navyPanel = Color(0xFF0A4A70);
  static const Color navyDeep = Color(0xFF001F35);
  static const Color navyLine = Color(0xFF123954);

  // Fondo de contenido
  static const Color background = Color(0xFFEEF2F5);

  // Tarjetas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F7F9);
  static const Color border = Color(0xFFE2E7EC);

  // Texto sobre tarjetas
  static const Color ink = Color(0xFF142430);
  static const Color inkSoft = Color(0xFF5C6B78);
  static const Color inkFaint = Color(0xFF98A6B1);

  // Acento de marca — turquesa del logo
  static const Color turquoise = Color(0xFF3FC1CC);
  static const Color turquoiseDeep = Color(0xFF1D8E98);

  // Estados
  static const Color route = Color(0xFF1E9E6C); // completado / GPS en vivo
  static const Color fail = Color(0xFFD6484A); // fallido / detener

  // Alias semánticos usados en pantallas
  static const Color primary = turquoise;
  static const Color primaryDark = turquoiseDeep;
  static const Color success = route;
  static const Color danger = fail;
  static const Color warning = turquoise;
  static const Color accentGreen = route;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;
  static const Color textMuted = inkFaint;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [navy, navyDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Sombras reutilizables — suaves, para tarjetas planas sobre fondo neutro.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14142430),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x24142430),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}

/// Radios consistentes.
class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
}

/// Tipografía Trimax:
/// - Space Grotesk para títulos y marca (carácter técnico, de tablero).
/// - Work Sans para texto de lectura y controles.
/// - JetBrains Mono para TODA cifra — km, horas, contadores — como un
///   cuentakilómetros digital. Es la firma tipográfica de la app.
class AppFonts {
  AppFonts._();

  static TextStyle display({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.workSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

/// Tema global de la app.
class AppTheme {
  AppTheme._();

  static const SystemUiOverlayStyle overlayLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.turquoise,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.turquoise,
      surface: AppColors.surface,
      error: AppColors.fail,
    );

    final textTheme = GoogleFonts.workSansTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      splashColor: AppColors.turquoise.withValues(alpha: 0.14),
      highlightColor: AppColors.turquoise.withValues(alpha: 0.06),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.display(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          foregroundColor: AppColors.ink,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppFonts.display(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: AppColors.inkSoft,
        labelStyle: AppFonts.body(color: AppColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.turquoiseDeep, width: 1.8),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentTextStyle: AppFonts.body(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
