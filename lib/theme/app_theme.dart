import 'package:flutter/material.dart';

/// Core palette for the Faby dark theme.
class FabyColors {
  FabyColors._();

  /// Turquoise accent from the brand brief.
  static const Color turquoise = Color(0xFF55E4C1);

  static const Color background = Color(0xFF0E1113);
  static const Color surface = Color(0xFF161A1D);
  static const Color surfaceHigh = Color(0xFF1F262B);
  static const Color outline = Color(0x22FFFFFF);
}

/// Builds the app-wide Material 3 dark theme with turquoise accents and large
/// rounded shapes for the minimalist look described in the brief.
ThemeData buildFabyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FabyColors.turquoise,
    brightness: Brightness.dark,
  ).copyWith(
    primary: FabyColors.turquoise,
    secondary: FabyColors.turquoise,
    surface: FabyColors.surface,
    onPrimary: const Color(0xFF00382E),
  );

  const rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FabyColors.background,
    canvasColor: FabyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Colors.white,
      ),
    ),
    cardTheme: const CardThemeData(
      color: FabyColors.surface,
      elevation: 0,
      shape: rounded,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: FabyColors.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: FabyColors.turquoise,
      foregroundColor: Color(0xFF00382E),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: FabyColors.turquoise,
      thumbColor: FabyColors.turquoise,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FabyColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
