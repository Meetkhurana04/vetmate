import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32); // #2E7D32
  static const Color secondaryColor = Color(0xFF81C784); // #81C784
  static const Color backgroundColor = Color(0xFFF8FAF8); // #F8FAF8
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1E291B);
  static const Color textLight = Color(0xFF6B7280);

  // ---------- Extended semantic colors (light only) ----------
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color elevatedColor = Colors.white;
  static const Color dividerColor = Color(0xFFE8EAE8);
  static const Color inputFillColor = Colors.white;
  static const Color chipColor = Color(0xFFF1F5F9);
  static const Color cardBorderColor = Color(0xFFE8EAE8);
  static const Color dangerColor = Colors.redAccent;
  static const Color successColor = Color(0xFF2E7D32);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF2563EB);
  static const Color tintColor = Color(0x0A000000);
  static const Color navBarColor = Colors.white;
  static const Color gradientStart = Color(0xFF2E7D32);
  static const Color gradientEnd = Color(0xFF1B5E20);
  static const Color shadowColor = Color(0x14000000);

  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textLight),
        hintStyle: const TextStyle(color: textLight),
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.displayLarge?.copyWith(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleLarge: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.titleLarge?.copyWith(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        headlineMedium: GoogleFonts.outfit(
          textStyle: baseTheme.textTheme.headlineMedium?.copyWith(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
