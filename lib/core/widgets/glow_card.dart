import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The base surface used across the app: a rounded, bordered card with an
/// optional accent glow. Tappable when [onTap] is provided.
class GlowCard extends StatelessWidget {
  const GlowCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.glow = false,
    this.color,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final decoration = BoxDecoration(
      color: color ?? tokens.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ??
            (glow
                ? tokens.accentColor.withValues(alpha: 0.35)
                : tokens.cardBorder),
      ),
      boxShadow: glow
          ? [
              BoxShadow(
                color: tokens.accentColor.withValues(alpha: 0.22),
                blurRadius: 28,
                spreadRadius: -6,
              ),
            ]
          : null,
    );

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
