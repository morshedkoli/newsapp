import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Colors.deepPurple;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.hindSiliguriTextTheme().copyWith(
        displayLarge: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        titleLarge: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.hindSiliguri(
          color: Colors.black87,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.hindSiliguri(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.hindSiliguri(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
