import 'package:flutter/material.dart';

class FinoraColors {
  static const gold = Color(0xFF89672E);
  static const goldBright = Color(0xFFC0A05B);
  static const income = Color(0xFF42C68A);
  static const expense = Color(0xFFE56972);
  static const warning = Color(0xFFD9A14E);
  static const goal = Color(0xFFAE82C9);
  static const investment = Color(0xFF6C9BDD);
  static const balance = Color(0xFFCBB56D);
}

class FinoraTheme {
  static ThemeData dark() => _theme(true);
  static ThemeData light() => _theme(false);

  static ThemeData _theme(bool dark) {
    final bg = dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final surface = dark ? const Color(0xFF080808) : const Color(0xFFFFFFFF);
    final field = dark ? const Color(0xFF101010) : const Color(0xFFF7F6F2);
    final line = dark ? const Color(0xFF202020) : const Color(0xFFE8E4DA);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: FinoraColors.gold,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: dark ? FinoraColors.goldBright : const Color(0xFF806027),
          secondary: FinoraColors.gold,
          surface: surface,
          error: dark ? FinoraColors.expense : const Color(0xFFC84A52),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FinoraColors.goldBright),
        ),
      ),
    );
  }
}

class PremiumRoute<T> extends PageRouteBuilder<T> {
  PremiumRoute({required Widget page})
    : super(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.06, 0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      );
}
