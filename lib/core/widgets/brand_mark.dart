import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The Stealthera brand mark with an optional accent glow.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 72, this.showGlow = true, super.key});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final glow = AppTokens.of(context).accentColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: glow.withValues(alpha: 0.32),
                  blurRadius: size * 0.5,
                  spreadRadius: -size * 0.08,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset(
          'assets/brand/stealthera_mark.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
