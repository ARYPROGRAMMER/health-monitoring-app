import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 72, this.showGlow = true, super.key});

  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final glowColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.28),
                  blurRadius: size * 0.46,
                  offset: Offset(0, size * 0.16),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/brand/stealthera_mark.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
