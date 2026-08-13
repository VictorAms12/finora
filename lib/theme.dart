import 'package:flutter/material.dart';

class FinoraColors {
  static const gold = Color(0xFF9B742B);
  static const goldBright = Color(0xFFC3A04D);
  static const income = Color(0xFF40C98A);
  static const expense = Color(0xFFEF666F);
  static const warning = Color(0xFFE0A64B);
  static const goal = Color(0xFFB783D7);
  static const investment = Color(0xFF6D9DEA);
  static const balance = Color(0xFFD0B96C);
}

class FinoraTheme {
  static ThemeData dark() {
    const bg = Color(0xFF000000);
    const surface = Color(0xFF0A0A0A);
    const surface2 = Color(0xFF111111);
    const line = Color(0xFF242424);

    final scheme = ColorScheme.fromSeed(
      seedColor: FinoraColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: FinoraColors.goldBright,
      secondary: FinoraColors.gold,
      surface: surface,
      error: FinoraColors.expense,
      onSurface: const Color(0xFFF3F0E9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: line,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Color(0xFFF3F0E9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Color(0xFF050505),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FinoraColors.goldBright),
        ),
      ),
    );
  }

  static ThemeData light() {
    const bg = Color(0xFFFFFFFF);
    const surface = Color(0xFFFFFFFF);
    const surface2 = Color(0xFFF6F5F1);
    const line = Color(0xFFE8E4DA);

    final scheme = ColorScheme.fromSeed(
      seedColor: FinoraColors.gold,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF856529),
      secondary: FinoraColors.gold,
      surface: surface,
      error: const Color(0xFFC94650),
      onSurface: const Color(0xFF171714),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: line,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Color(0xFF171714),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FinoraColors.gold),
        ),
      ),
    );
  }
}
