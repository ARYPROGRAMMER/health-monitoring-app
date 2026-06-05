import 'package:flutter/material.dart';

/// Type system: Space Grotesk for proportional text, Space Mono for data,
/// labels, units and tabular numerals (the technical "device" feel).
class AppTypography {
  const AppTypography._();

  static const grotesk = 'SpaceGrotesk';
  static const mono = 'SpaceMono';

  static TextTheme textTheme(Color onSurface, Color muted) {
    TextStyle g(double size, FontWeight w, {double height = 1.2, double ls = 0}) {
      return TextStyle(
        fontFamily: grotesk,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: ls,
        color: onSurface,
      );
    }

    return TextTheme(
      displayLarge: g(64, FontWeight.w300, height: 1.0, ls: -1),
      displayMedium: g(52, FontWeight.w300, height: 1.0, ls: -1),
      displaySmall: g(40, FontWeight.w400, height: 1.0),
      headlineLarge: g(32, FontWeight.w600),
      headlineMedium: g(28, FontWeight.w600),
      headlineSmall: g(24, FontWeight.w600),
      titleLarge: g(20, FontWeight.w600),
      titleMedium: g(17, FontWeight.w600),
      titleSmall: g(15, FontWeight.w600),
      bodyLarge: g(16, FontWeight.w400, height: 1.45),
      bodyMedium: g(14, FontWeight.w400, height: 1.5).copyWith(color: muted),
      bodySmall: g(12.5, FontWeight.w400, height: 1.45).copyWith(color: muted),
      labelLarge: monoStyle(14, FontWeight.w700, color: onSurface),
      labelMedium: monoStyle(12.5, FontWeight.w400, color: muted),
      labelSmall: monoStyle(11, FontWeight.w400, color: muted),
    );
  }

  /// Monospace style used for stat rows, units, date strip and the device feel.
  static TextStyle monoStyle(
    double size,
    FontWeight weight, {
    Color? color,
    double ls = 0.2,
    double height = 1.2,
  }) {
    return TextStyle(
      fontFamily: mono,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: ls,
      height: height,
      color: color,
    );
  }

  /// The huge hero numeral (e.g. "74", "1240").
  static TextStyle hero(Color color, {double size = 66}) {
    return TextStyle(
      fontFamily: grotesk,
      fontSize: size,
      fontWeight: FontWeight.w300,
      height: 1.0,
      letterSpacing: -1.5,
      color: color,
    );
  }
}
