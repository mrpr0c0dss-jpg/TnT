import 'package:flutter/material.dart';

class AppTheme {
  // Official TNT Brand Colors (Matching Web Reference Store)
  static const Color headerBg = Color(0xFF00D09C);      // Mint Green Header
  static const Color topStripBg = Color(0xFF1F1934);    // Dark Violet Announcement Strip
  static const Color mintGreen = Color(0xFF00D09C);     // Brand Gaming Green
  static const Color fireOrange = Color(0xFFFF6B24);    // Gaming Action Orange
  static const Color electricBlue = Color(0xFF168BFF);  // Action Blue
  static const Color cyan = Color(0xFF00BFA5);          // Cyan Accent
  static const Color purple = Color(0xFF8B5CF6);        // Purple Accent
  static const Color emeraldGreen = Color(0xFF10B981);  // Success Green
  static const Color amberGold = Color(0xFFF59E0B);     // Warning/Gold
  static const Color errorRed = Color(0xFFDC2626);      // Error Red

  // Crisp Gaming Store Light Surfaces (Default)
  static const Color bgPrimary = Color(0xFFEBF3FA);     // Soft Ice Blue Background
  static const Color bgSecondary = Color(0xFFFFFFFF);   // Pure White Surfaces
  static const Color bgTertiary = Color(0xFFE2ECF6);    // Subtle Surface Shade
  static const Color bgCard = Color(0xFFFFFFFF);        // Clean White Cards
  static const Color bgCardHover = Color(0xFFF8FAFC);   // Subtle Card Hover
  static const Color borderSubtle = Color(0xFFEBEFF5);  // Subtle Dividers
  static const Color borderCard = Color(0xFFE2E8F0);    // Card Borders
  static const Color borderLight = Color(0xFFCBD5E1);   // Light Gray Borders

  // Typography Colors (Dark Slate on Light)
  static const Color textMain = Color(0xFF0F172A);      // Primary Dark Slate
  static const Color textMuted = Color(0xFF475569);     // Secondary Text
  static const Color textDim = Color(0xFF64748B);       // Dim/Hint Text

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [fireOrange, Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [mintGreen, Color(0xFF05B681)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF00D09C), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: mintGreen,
      colorScheme: const ColorScheme.light(
        primary: mintGreen,
        secondary: fireOrange,
        surface: bgCard,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderCard, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fireOrange,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: mintGreen,
          side: const BorderSide(color: mintGreen, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: const TextStyle(color: textDim, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderCard, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderCard, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: mintGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: fireOrange,
        unselectedItemColor: textDim,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderCard, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 20,
      ),
    );
  }

  // Backward compatibility getter
  static ThemeData get darkTheme => lightTheme;
}
