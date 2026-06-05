import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'signature_painters.dart';

/// Stylised activity route map with a side action rail (dashboard).
class RouteMapCard extends StatelessWidget {
  const RouteMapCard({this.height = 188, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: RouteMapPainter(
                  color: tokens.glow,
                  line: (tokens.isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  base: tokens.isDark
                      ? const Color(0xFF1E2226)
                      : const Color(0xFFE8EDEB),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 14,
              bottom: 14,
              child: Container(
                width: 38,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF15161C)),
                    Icon(Icons.person_rounded, size: 17, color: Color(0xFF15161C)),
                    Icon(Icons.layers_rounded, size: 17, color: Color(0xFF15161C)),
                    Icon(Icons.refresh_rounded, size: 17, color: Color(0xFF15161C)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
