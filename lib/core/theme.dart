// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core palette (Antique Study) ──
  static const Color page        = Color(0xFFF4EDD8);
  static const Color surface     = Color(0xFFFAF6EE);
  static const Color surfaceAlt  = Color(0xFFEDE0C4);
  static const Color border      = Color(0xFFD3C09A);
  static const Color borderSoft  = Color(0xFFE3D5B4);

  // ── Text ──
  static const Color ink         = Color(0xFF1E1A14);
  static const Color mahogany    = Color(0xFF3D3025);
  static const Color tobacco     = Color(0xFF6B5B43);
  static const Color pewter      = Color(0xFF9A8C78);
  static const Color fog         = Color(0xFFBFB39D);

  // ── Brand accent ──
  static const Color amber       = Color(0xFF9A6F2A);
  static const Color amberRich   = Color(0xFFB8852E);
  static const Color amberPale   = Color(0xFFE8D4A0);

  // ── Supporting ──
  static const Color sienna      = Color(0xFF7A3325);
  static const Color forest      = Color(0xFF3A5A30);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: page,
    colorScheme: ColorScheme.light(
      primary: amber,
      surface: surface,
      error: sienna,
    ),
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 36, fontWeight: FontWeight.w700, color: ink,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28, fontWeight: FontWeight.w700, color: ink,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w600, color: ink,
      ),
      bodyLarge: GoogleFonts.dmSans(fontSize: 16, color: tobacco),
      bodyMedium: GoogleFonts.dmSans(fontSize: 14, color: tobacco),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: amberPale,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.dmSans(fontSize: 12, color: tobacco),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.w600, color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: amber, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: amber,
        foregroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
