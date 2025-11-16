import 'package:flutter/material.dart';

class AppTheme {
  // Colors from Figma design
  static const Color bgBase = Color(0xFF0B0D10);
  static const Color bgRaised = Color(0xFF111318);
  static const Color bgPopover = Color(0xFF161A20);
  
  static const Color textPrimary = Color(0xFFE9EDF2);
  static const Color textSecondary = Color(0xFF9AA4AF);
  static const Color textInverse = Color(0xFF0B0D10);
  
  static const Color brandPrimary = Color(0xFF6AA6FF);
  static const Color brandAccent = Color(0xFF7AF0C1);
  
  static const Color stateSuccess = Color(0xFF21D19F);
  static const Color stateWarning = Color(0xFFFFC252);
  static const Color stateDanger = Color(0xFFFF5C6C);
  static const Color stateInfo = Color(0xFF6AA6FF);
  
  static const Color surfaceCard = Color(0xFF111318);
  static const Color surfaceChip = Color(0xFF1C222B);
  static const Color surfaceBorder = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)

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

