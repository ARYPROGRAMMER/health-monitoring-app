import 'package:flutter/material.dart';

import 'app_accent.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Builds the full [ThemeData] for a given accent + brightness.
class AppTheme {
  const AppTheme._();

  static const _onPrimary = Color(0xFF15161C);
  static const _danger = Color(0xFFFF5A6E);
  static const _warning = Color(0xFFE8B546);

  static ThemeData build({
    required AppAccent accent,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final primary = accent.primary;

    final onSurface = isDark ? const Color(0xFFF4F5F6) : const Color(0xFF14181B);
    final muted = isDark ? const Color(0xFF9BA0A6) : const Color(0xFF626A70);
    final surface = isDark ? const Color(0xFF0C0D0F) : Colors.white;
    final outline = isDark ? const Color(0xFF26282C) : const Color(0xFFDCE3E0);

    final scheme =
        ColorScheme.fromSeed(seedColor: primary, brightness: brightness)
            .copyWith(
              primary: primary,
              onPrimary: _onPrimary,
              secondary: accent.glow,
              onSecondary: _onPrimary,
              surface: surface,
              onSurface: onSurface,
              onSurfaceVariant: muted,
              outline: outline,
              outlineVariant: isDark
                  ? const Color(0xFF1C1E21)
                  : const Color(0xFFE9EFEC),
              error: _danger,
            );

    final tokens = AppTokens(
      accent: accent,
      accentColor: primary,
      glow: accent.glow,
      blob: accent.blob,
      card: isDark ? const Color(0xFF111315) : Colors.white,
      cardBorder: isDark ? const Color(0xFF222528) : const Color(0xFFE5EBE8),
      elevatedCard: isDark ? const Color(0xFF181A1D) : const Color(0xFFF4F8F6),
      track: isDark ? const Color(0xFF24272B) : const Color(0xFFE4EAE7),
      textMuted: muted,
      danger: _danger,
      warning: _warning,
      success: const Color(0xFF3CCB74),
      isDark: isDark,
    );

    final textTheme = AppTypography.textTheme(onSurface, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF000000)
          : accent.lightWash,
      fontFamily: AppTypography.grotesk,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.elevatedCard,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.elevatedCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF131517)
            : Colors.white.withValues(alpha: 0.9),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: primary),
        prefixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(primary, width: 1.6),
        errorBorder: _inputBorder(_danger),
        focusedErrorBorder: _inputBorder(_danger, width: 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _onPrimary,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: AppTypography.monoStyle(15, FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary.withValues(alpha: 0.16),
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: AppTypography.monoStyle(15, FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: tokens.track,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.14),
        trackHeight: 6,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.35)
              : tokens.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: tokens.track,
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
