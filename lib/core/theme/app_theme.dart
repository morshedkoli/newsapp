import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ============ Greenish Theme Colors ============
  static const Color primaryColor = Color(0xFF00BFA5);       // Teal accent
  static const Color primaryLight = Color(0xFFE0F7F1);       // Light teal tint
  static const Color primaryDark = Color(0xFF00897B);        // Dark teal
  static const Color accentColor = Color(0xFF4CAF50);        // Green accent
  static const Color surfaceColor = Color(0xFFF5FAF9);       // Off-white with green tint

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
        primary: primaryColor,
        secondary: accentColor,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.tiroBanglaTextTheme().copyWith(
        displayLarge: GoogleFonts.tiroBangla(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: GoogleFonts.tiroBangla(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        titleLarge: GoogleFonts.tiroBangla(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.tiroBangla(
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.tiroBangla(
          color: Colors.black87,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.tiroBangla(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.tiroBangla(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryLight,
        backgroundColor: Colors.white,
      ),
    );
  }
}
