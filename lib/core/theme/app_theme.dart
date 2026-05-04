import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color kBg = Color(0xFF0D0B08);
  static const Color kSurface = Color(0xFF1C1710);
  static const Color kAccent = Color(0xFFD4A843);
  static const Color kTerracotta = Color(0xFFBF6B3A);
  static const Color kAncientBlue = Color(0xFF3A6D8C);
  static const Color kParchment = Color(0xFFF5ECD7);
  static const Color kGlass = Color(0xFF1C1710);
  static const Color kGlassBorder = Color(0xFF3A3020);
  static const Color errorColor = Color(0xFFD94F3D);
  static const Color accent = kAccent;
  static const Color backgroundColor = kBg;
  static const Color surfaceColor = kSurface;

  static ThemeData get theme => ThemeData(
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
      error: errorColor,
    ),
    textTheme: GoogleFonts.outfitTextTheme(
      const TextTheme(
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
      fillColor: const Color(0xFF221D12),
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
      labelStyle: const TextStyle(color: Color(0xAAF5ECD7)),
      hintStyle: const TextStyle(color: Color(0x66F5ECD7)),
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
      contentTextStyle: const TextStyle(color: kParchment),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
