import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta Trimax — "tablero de despacho": chasis oscuro tipo tablero de
/// moto + tickets de papel para el contenido, con un acento ámbar de
/// señalización. Fuente única de verdad para colores.
class AppColors {
  AppColors._();

  // Chasis oscuro (headers, GPS, splash, login)
  static const Color asphalt = Color(0xFF15151B);
  static const Color asphaltPanel = Color(0xFF201F27);
  static const Color asphaltLine = Color(0xFF34333D);

  // Tablero / fondo de contenido (tipo clipboard)
  static const Color board = Color(0xFFE9E2D0);

  // Ticket de papel (tarjetas)
  static const Color paper = Color(0xFFFCFAF2);
  static const Color paperMuted = Color(0xFFF1EBDA);
  static const Color paperLine = Color(0xFFDED3B4);

  // Texto sobre papel
  static const Color ink = Color(0xFF1C1A17);
  static const Color inkSoft = Color(0xFF6E6858);
  static const Color inkFaint = Color(0xFFA79E89);

  // Acento de marca — ámbar de señalización
  static const Color amber = Color(0xFFFFB020);
  static const Color amberDeep = Color(0xFFCC7A00);

  // Estados
  static const Color route = Color(0xFF3FAE6B); // completado / GPS en vivo
  static const Color fail = Color(0xFFE0524A); // fallido / detener

  // Alias retrocompatibles usados en pantallas
  static const Color primary = amber;
  static const Color primaryDark = amberDeep;
  static const Color success = route;
  static const Color danger = fail;
  static const Color warning = amber;
  static const Color navy = asphalt;
  static const Color accentGreen = route;
  static const Color background = board;
  static const Color surface = paper;
  static const Color surfaceMuted = paperMuted;
  static const Color textPrimary = ink;
  static const Color textSecondary = inkSoft;
  static const Color textMuted = inkFaint;
  static const Color border = paperLine;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [asphalt, asphaltPanel],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Sombras reutilizables — cálidas, como papel levantado del tablero.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x1F1C1A17),
      blurRadius: 14,
      offset: Offset(0, 5),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x261C1A17),
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
      seedColor: AppColors.amber,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.amber,
      surface: AppColors.paper,
      error: AppColors.fail,
    );

    final textTheme = GoogleFonts.workSansTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.board,
      textTheme: textTheme,
      splashColor: AppColors.amber.withValues(alpha: 0.14),
      highlightColor: AppColors.amber.withValues(alpha: 0.06),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.asphalt,
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
        color: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
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
          side: const BorderSide(color: AppColors.paperLine),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppFonts.body(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: AppColors.inkSoft,
        labelStyle: AppFonts.body(color: AppColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.paperLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.amberDeep, width: 1.8),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.asphalt,
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
        color: AppColors.paperLine,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
