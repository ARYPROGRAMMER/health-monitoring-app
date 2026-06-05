import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Full-screen backdrop: deep black with a soft accent glow on dark, or an
/// accent-tinted wash on light. Cheap (no blur filters) for fast scrolling.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, this.glowAlignment, super.key});

  final Widget child;
  final Alignment? glowAlignment;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    if (!tokens.isDark) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: glowAlignment ?? const Alignment(0, -0.95),
          radius: 1.1,
          colors: [
            tokens.accentColor.withValues(alpha: 0.16),
            const Color(0xFF000000),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
      child: child,
    );
  }
}
