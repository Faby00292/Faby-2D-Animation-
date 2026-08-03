import 'package:flutter/material.dart';

/// Central design tokens and Material 3 themes for Faby 2D Animation.
///
/// The signature accent is a turquoise (`#55E4C1`) used across both the dark
/// (primary) and light themes. Surfaces lean toward deep near-black greens in
/// dark mode to give the glassmorphism panels something to sit on.
class AppTheme {
  AppTheme._();

  /// Turquoise brand accent.
  static const Color accent = Color(0xFF55E4C1);
  static const Color accentDim = Color(0xFF2FBFA0);

  // Dark palette.
  static const Color darkBackground = Color(0xFF0E1512);
  static const Color darkSurface = Color(0xFF141C19);
  static const Color darkSurfaceHigh = Color(0xFF1B2622);

  /// Corner radius shared by cards, panels and large buttons.
  static const double radius = 20;
  static const double radiusSmall = 12;

  static ThemeData dark() => _base(Brightness.dark);
  static ThemeData light() => _base(Brightness.light);

  static ThemeData _base(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: accent,
      surface: isDark ? darkSurface : null,
    );

    final Color scaffold = isDark ? darkBackground : const Color(0xFFF3F6F5);

    // Only component themes whose config class name has been stable across
    // Flutter versions are set here (FloatingActionButtonThemeData,
    // FilledButtonThemeData, SliderThemeData, SnackBarThemeData). Card / dialog
    // / app-bar / input styling is applied inline at the call sites to avoid the
    // XTheme -> XThemeData field-type migration in newer SDKs.
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      brightness: brightness,
      splashFactory: InkSparkle.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
        inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.15),
        trackHeight: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkSurfaceHigh : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
    );
  }
}
