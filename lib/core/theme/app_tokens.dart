import 'package:flutter/material.dart';

import 'app_accent.dart';

/// Custom design tokens that don't fit the Material [ColorScheme], exposed as a
/// [ThemeExtension] so widgets read them via `Theme.of(context).extension`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.accent,
    required this.accentColor,
    required this.glow,
    required this.blob,
    required this.card,
    required this.cardBorder,
    required this.elevatedCard,
    required this.track,
    required this.textMuted,
    required this.danger,
    required this.warning,
    required this.success,
    required this.isDark,
  });

  final AppAccent accent;
  final Color accentColor;
  final Color glow;
  final List<Color> blob;
  final Color card;
  final Color cardBorder;
  final Color elevatedCard;
  final Color track;
  final Color textMuted;
  final Color danger;
  final Color warning;
  final Color success;
  final bool isDark;

  static AppTokens of(BuildContext context) =>
      Theme.of(context).extension<AppTokens>()!;

  @override
  AppTokens copyWith({
    AppAccent? accent,
    Color? accentColor,
    Color? glow,
    List<Color>? blob,
    Color? card,
    Color? cardBorder,
    Color? elevatedCard,
    Color? track,
    Color? textMuted,
    Color? danger,
    Color? warning,
    Color? success,
    bool? isDark,
  }) {
    return AppTokens(
      accent: accent ?? this.accent,
      accentColor: accentColor ?? this.accentColor,
      glow: glow ?? this.glow,
      blob: blob ?? this.blob,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      elevatedCard: elevatedCard ?? this.elevatedCard,
      track: track ?? this.track,
      textMuted: textMuted ?? this.textMuted,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      accent: t < 0.5 ? accent : other.accent,
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      blob: [
        Color.lerp(blob.first, other.blob.first, t)!,
        Color.lerp(blob.last, other.blob.last, t)!,
      ],
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      elevatedCard: Color.lerp(elevatedCard, other.elevatedCard, t)!,
      track: Color.lerp(track, other.track, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
