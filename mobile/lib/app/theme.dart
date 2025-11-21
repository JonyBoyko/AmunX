import 'package:flutter/material.dart';

class AppTheme {
  // Colors from Figma design
  static const Color bgBase = Color(0xFF0A0A0F);
  static const Color bgRaised = Color(0xFF14141E);
  static const Color bgPopover = Color(0xFF1A1E28);
  static const Color bgOverlay = Color(0xCC0A0A0F);
  static const Color bgInput = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const Color bgMuted = Color(0x19FFFFFF); // rgba(255,255,255,0.10)
  static const Color bgGlassLight = Color(0x0DFFFFFF); // glass light overlay
  
  static const Color textPrimary = Color(0xFFE9EDF2);
  static const Color textSecondary = Color(0xFF9AA4AF);
  static const Color textInverse = Color(0xFF0B0D10);
  
  static const Color brandPrimary = Color(0xFF00F0FF);
  static const Color brandAccent = Color(0xFF9333FF);
  static const Color neonBlue = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF0055);
  static const Color neonPurple = Color(0xFF9333FF);
  static const Color destructive = neonPink;
  
  static const Color stateSuccess = Color(0xFF21D19F);
  static const Color stateWarning = Color(0xFFFFC252);
  static const Color stateDanger = Color(0xFFFF5C6C);
  static const Color stateInfo = Color(0xFF6AA6FF);
  
  static const Color surfaceCard = Color(0xFF14141E);
  static const Color surfaceChip = Color(0xFF1E2430);
  static const Color surfaceBorder = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  static const Color glassSurface = Color(0x9914141E); // rgba(20,20,30,0.6)
  static const Color glassSurfaceDense = Color(0xB314141E); // rgba(20,20,30,0.7)
  static const Color glassStroke = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  static const Color glassSurfaceLight = bgGlassLight;

  // Effects
  static const double blurSm = 8.0;
  static const double blurMd = 14.0;
  static const double blurLg = 24.0;

  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x8000F0FF),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x4D00F0FF),
      blurRadius: 40,
      spreadRadius: -4,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> glowAccent = [
    BoxShadow(
      color: Color(0x809333FF),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x4D9333FF),
      blurRadius: 40,
      spreadRadius: -4,
      offset: Offset(0, 16),
    ),
  ];
  static const List<BoxShadow> glowPink = [
    BoxShadow(
      color: Color(0x80FF0055),
      blurRadius: 22,
      spreadRadius: -2,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x4DFF0055),
      blurRadius: 40,
      spreadRadius: -4,
      offset: Offset(0, 18),
    ),
  ];

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF1A0F2E),
      Color(0xFF0F1A2E),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonBlue, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Charts
  static const Color chart1 = neonBlue;
  static const Color chart2 = neonPurple;
  static const Color chart3 = neonPink;
  static const Color chart4 = Color(0xFF00FF88);
  static const Color chart5 = Color(0xFFFFAA00);

  // Radius
  static const double radiusXs = 6.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 28.0;

  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgBase,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: surfaceCard,
        error: stateDanger,
        onPrimary: textInverse,
        onSecondary: textInverse,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgRaised,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: textInverse,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
      ),
    );
  }
}

