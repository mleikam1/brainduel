import 'package:flutter/material.dart';

class BrainDuelColors {
  static const midnight = Color(0xFF0B132B);
  static const slate = Color(0xFF1C2541);
  static const steel = Color(0xFF3A506B);
  static const glacier = Color(0xFF5BC0EB);
  static const neon = Color(0xFF64FFDA);
  static const ember = Color(0xFFFFB703);
  static const rose = Color(0xFFE63946);
  static const cloud = Color(0xFFF7F9FB);
  static const fog = Color(0xFFE1E8F0);
}

class BrainDuelSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

class BrainDuelRadii {
  static const Radius sm = Radius.circular(12);
  static const Radius md = Radius.circular(18);
  static const Radius lg = Radius.circular(24);
}

class BrainDuelTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: BrainDuelColors.glacier,
      onPrimary: Colors.white,
      secondary: BrainDuelColors.neon,
      onSecondary: BrainDuelColors.midnight,
      error: BrainDuelColors.rose,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: BrainDuelColors.midnight,
      tertiary: BrainDuelColors.ember,
      onTertiary: BrainDuelColors.midnight,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: BrainDuelColors.cloud,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: BrainDuelColors.midnight,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrainDuelColors.fog,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: BrainDuelColors.steel.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: BrainDuelColors.fog),
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: BrainDuelColors.fog),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BrainDuelColors.glacier,
      onPrimary: BrainDuelColors.midnight,
      secondary: BrainDuelColors.neon,
      onSecondary: BrainDuelColors.midnight,
      error: BrainDuelColors.rose,
      onError: Colors.white,
      surface: BrainDuelColors.slate,
      onSurface: Colors.white,
      tertiary: BrainDuelColors.ember,
      onTertiary: BrainDuelColors.midnight,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: BrainDuelColors.midnight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        color: BrainDuelColors.slate,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: BrainDuelColors.steel,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
      ),
    );
  }
}
