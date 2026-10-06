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

class FinoraAccentOption {
  final String key;
  final String label;
  final Color light;
  final Color dark;

  const FinoraAccentOption({
    required this.key,
    required this.label,
    required this.light,
    required this.dark,
  });
}

class FinoraTheme {
  static const accentOptions = <FinoraAccentOption>[
    FinoraAccentOption(
      key: 'gold',
      label: 'Dourado',
      light: Color(0xFF806027),
      dark: Color(0xFFC0A05B),
    ),
    FinoraAccentOption(
      key: 'blue',
      label: 'Azul',
      light: Color(0xFF2563EB),
      dark: Color(0xFF60A5FA),
    ),
    FinoraAccentOption(
      key: 'green',
      label: 'Verde',
      light: Color(0xFF15803D),
      dark: Color(0xFF4ADE80),
    ),
    FinoraAccentOption(
      key: 'purple',
      label: 'Roxo',
      light: Color(0xFF7C3AED),
      dark: Color(0xFFA78BFA),
    ),
    FinoraAccentOption(
      key: 'pink',
      label: 'Rosa',
      light: Color(0xFFBE185D),
      dark: Color(0xFFF472B6),
    ),
    FinoraAccentOption(
      key: 'orange',
      label: 'Laranja',
      light: Color(0xFFC2410C),
      dark: Color(0xFFFB923C),
    ),
    FinoraAccentOption(
      key: 'cyan',
      label: 'Ciano',
      light: Color(0xFF0E7490),
      dark: Color(0xFF22D3EE),
    ),
  ];

  static FinoraAccentOption accentOption(String key) => accentOptions.firstWhere(
        (option) => option.key == key,
        orElse: () => accentOptions.first,
      );

  static Color accentColor(String key, {required bool dark}) {
    final option = accentOption(key);
    return dark ? option.dark : option.light;
  }

  static ThemeData dark({String accentKey = 'gold'}) =>
      _theme(true, accentKey);
  static ThemeData light({String accentKey = 'gold'}) =>
      _theme(false, accentKey);

  static ThemeData _theme(bool dark, String accentKey) {
    final bg = dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final surface = dark ? const Color(0xFF080808) : const Color(0xFFFFFFFF);
    final field = dark ? const Color(0xFF101010) : const Color(0xFFF7F6F2);
    final line = dark ? const Color(0xFF202020) : const Color(0xFFE8E4DA);
    final accent = accentColor(accentKey, dark: dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: accent,
      secondary: accent,
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: dark ? Colors.black : Colors.white,
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
          borderSide: BorderSide(color: accent),
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
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(.06, 0), end: Offset.zero).animate(curve),
                child: child,
              ),
            );
          },
        );
}
