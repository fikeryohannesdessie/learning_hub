import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Heritage Cultural Palette ──────────────────────────────────────────────
  /// Deep warm almost-black — like charred ancient stone
  static const Color kBg = Color(0xFF0D0B08);

  /// Warm brown-black surface — like aged parchment in shadow
  static const Color kSurface = Color(0xFF1C1710);

  /// Heritage gold — the primary accent, UNESCO medal gold
  static const Color kAccent = Color(0xFFD4A843);

  /// Terracotta — secondary warm accent
  static const Color kTerracotta = Color(0xFFBF6B3A);

  /// Ancient lapis blue — cool contrast accent
  static const Color kAncientBlue = Color(0xFF3A6D8C);

  /// Parchment white — for soft text and highlights
  static const Color kParchment = Color(0xFFF5ECD7);

  /// Glass surface — slight warm tint
  static const Color kGlass = Color(0xFF1C1710);

  /// Glass border — hairline warm-white stroke
  static const Color kGlassBorder = Color(0xFF3A3020);

  // ── Legacy aliases kept for backward compat ───────────────────────────────
  static const Color primaryColor = kAccent;
  static const Color secondaryColor = kTerracotta;
  static const Color accentColor = kAccent;
  static const Color backgroundColor = kBg;
  static const Color surfaceColor = kSurface;
  static const Color errorColor = Color(0xFFD94F3D);
  static const Color textDark = kParchment;
  static const Color textLight = Color(0xAAF5ECD7);
  static const Color textWhite = Colors.white;

  /// Role colours
  static const Color ViewerColor = kAccent;
  static const Color ContributorColor = kTerracotta;
  static const Color adminColor = kAncientBlue;

  // ── Main Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkGlassTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBg,
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      secondary: kTerracotta,
      tertiary: kAncientBlue,
      surface: kSurface,
      onPrimary: kBg,
      onSurface: kParchment,
      error: Color(0xFFD94F3D),
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: kParchment, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
          color: kParchment,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: kParchment,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: kParchment,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        headlineSmall: TextStyle(
          color: kParchment,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(color: kParchment, fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xAAF5ECD7), fontSize: 14),
        bodySmall: TextStyle(color: Color(0x88F5ECD7), fontSize: 12),
        labelLarge: TextStyle(
          color: kAccent,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: kParchment,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.outfit().fontFamily,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kGlassBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: GoogleFonts.outfit().fontFamily,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kAccent,
        textStyle: TextStyle(
          fontFamily: GoogleFonts.outfit().fontFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF221D12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kGlassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kGlassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
      labelStyle: TextStyle(color: Color(0xAAF5ECD7)),
      hintStyle: TextStyle(color: Color(0x66F5ECD7)),
      prefixIconColor: kAccent,
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: kAccent,
      labelColor: kParchment,
      unselectedLabelColor: const Color(0x66F5ECD7),
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.outfit().fontFamily,
        fontSize: 13,
        letterSpacing: 1.0,
      ),
    ),
    iconTheme: const IconThemeData(color: kParchment),
    dividerColor: kGlassBorder,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kSurface,
      contentTextStyle: TextStyle(color: kParchment),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
