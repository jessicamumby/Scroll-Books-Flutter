// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── New Warm Punch palette ──
  static const Color cream       = Color(0xFFFFF8F0);
  static const Color parchment   = Color(0xFFF5EDE0);
  static const Color warmGold    = Color(0xFFD4A853);
  static const Color tomato      = Color(0xFFD94F30);
  static const Color tomatoLight = Color(0xFFF4DDD7);
  static const Color amber       = Color(0xFFE8A838);
  static const Color amberLight  = Color(0xFFFDF0D5);
  static const Color ink         = Color(0xFF2C2118);
  static const Color inkMid      = Color(0xFF5C4A3A);
  static const Color inkLight    = Color(0xFF8C7B6B);
  static const Color sage        = Color(0xFF7A9E7E);
  static const Color sageLight   = Color(0xFFE4EDE5);
  static const Color warmWhite   = Color(0xFFFFFDFB);

  // ── Backward-compat aliases (for auth/reader/profile screens) ──
  static const Color page       = cream;
  static const Color surface    = cream;
  static const Color surfaceAlt = parchment;
  static const Color border     = parchment;
  static const Color borderSoft = parchment;
  static const Color brand      = tomato;
  static const Color brandDark  = tomato;
  static const Color brandPale  = tomatoLight;
  static const Color brandWash  = tomatoLight;
  static const Color mahogany   = ink;
  static const Color tobacco    = inkMid;
  static const Color pewter     = inkLight;
  static const Color fog        = inkLight;
  static const Color forest     = sage;
  static const Color forestPale = sageLight;

  // ── Cover art (kept for book gradients) ──
  static const Color coverDeep  = Color(0xFF2C3E50);
  static const Color coverRich  = Color(0xFF4A1942);
  static const Color sienna     = Color(0xFF7A3325);

  // ── Layout constants ──
  static const double cardRadius   = 16.0;
  static const double buttonRadius = 12.0;
  static const double smallRadius  = 10.0;

  // ── Typography helpers ──
  static TextStyle headingStyle({
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w700,
    Color color = ink,
  }) => GoogleFonts.playfairDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle bodyStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ink,
  }) => GoogleFonts.playfairDisplay(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );

  static TextStyle monoLabel({
    double fontSize = 10,
    FontWeight fontWeight = FontWeight.w600,
    Color color = inkLight,
    double letterSpacing = 2.0,
  }) => GoogleFonts.sourceCodePro(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color,
  ).copyWith(textBaseline: TextBaseline.alphabetic);

  // ── Shadow helpers ──
  static List<BoxShadow> warmShadow({
    Color? color,
    double blur = 12,
    double spread = 0,
    Offset offset = const Offset(0, 4),
  }) => [
    BoxShadow(
      color: (color ?? tomato).withValues(alpha: 0.15),
      blurRadius: blur,
      spreadRadius: spread,
      offset: offset,
    ),
  ];

  // ── Theme data ──
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.light(
      primary: tomato,
      onPrimary: cream,
      surface: cream,
      onSurface: ink,
      error: sienna,
      onError: cream,
    ),
    textTheme: GoogleFonts.playfairDisplayTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 36, fontWeight: FontWeight.w700, color: ink,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28, fontWeight: FontWeight.w700, color: ink,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w600, color: ink,
      ),
      bodyLarge: GoogleFonts.playfairDisplay(fontSize: 16, color: inkMid),
      bodyMedium: GoogleFonts.playfairDisplay(fontSize: 14, color: inkMid),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cream,
      indicatorColor: tomatoLight,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.playfairDisplay(fontSize: 12, color: inkMid),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cream,
      foregroundColor: ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 18, fontWeight: FontWeight.w600, color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
        borderSide: BorderSide(color: parchment),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
        borderSide: BorderSide(color: parchment),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
        borderSide: BorderSide(color: tomato, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tomato,
        foregroundColor: cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: GoogleFonts.playfairDisplay(
          fontSize: 16, fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
