// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core palette (Warm Punch) ──
  static const Color page        = Color(0xFFFFF9F2);
  static const Color surface     = Color(0xFFFFF0E0);
  static const Color surfaceAlt  = Color(0xFFF0E0CC);
  static const Color border      = Color(0xFFF0E0CC);
  static const Color borderSoft  = Color(0xFFF5EDE0);

  // ── Text ──
  static const Color ink         = Color(0xFF1C0F00);
  static const Color mahogany    = Color(0xFF3D3025);
  static const Color tobacco     = Color(0xFF7A5C44);
  static const Color pewter      = Color(0xFFA08060);
  static const Color fog         = Color(0xFFBFB39D);

  // ── Brand accent (values updated; names renamed in Task 2) ──
  static const Color amber       = Color(0xFFFF4D2E);
  static const Color amberRich   = Color(0xFFE03A1C);
  static const Color amberPale   = Color(0xFFFFD0C8);
  static const Color amberWash   = Color(0xFFFFF2F0);

  // ── Cover art ──
  static const Color coverDeep   = Color(0xFF2C3E50);
  static const Color coverRich   = Color(0xFF4A1942);

  // ── Supporting ──
  static const Color sienna      = Color(0xFF7A3325);
  static const Color forest      = Color(0xFF3A5A30);
  static const Color forestPale  = Color(0xFFC8D8C4);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: page,
    colorScheme: ColorScheme.light(
      primary: amber,
      onPrimary: surface,
      surface: surface,
      onSurface: ink,
      error: sienna,
      onError: surface,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.lora(
        fontSize: 36, fontWeight: FontWeight.w700, color: ink,
      ),
      displayMedium: GoogleFonts.lora(
        fontSize: 28, fontWeight: FontWeight.w700, color: ink,
      ),
      titleLarge: GoogleFonts.lora(
        fontSize: 20, fontWeight: FontWeight.w600, color: ink,
      ),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, color: tobacco),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, color: tobacco),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: amberPale,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.nunito(fontSize: 12, color: tobacco),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.lora(
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
        textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
